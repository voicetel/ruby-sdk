# frozen_string_literal: true

require "tempfile"

RSpec.describe VoiceTel::Resources::Fax do
  let(:client) { new_client }
  let(:pdf) { "%PDF-1.4 fax document bytes" }

  describe "#numbers" do
    it "GETs /v2.2/numbers/fax" do
      stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers/fax")
        .to_return(status: 200, body: envelope(numbers: [
                                                { number: "2015550123", destinationId: 7, email: "fax@example.com" },
                                                { number: "2015550199", destinationId: 0, email: "account@example.com" }
                                              ]))
      result = client.fax.numbers
      expect(result).to be_a(VoiceTel::Models::FaxNumbersData)
      expect(result.numbers.first).to be_a(VoiceTel::Models::FaxNumberEntry)
      expect(result.numbers.first.number).to eq("2015550123")
      expect(result.numbers.first.destination_id).to eq(7)
      expect(result.numbers.last.email).to eq("account@example.com")
    end
  end

  describe "#send_fax" do
    let(:job_envelope) do
      envelope(
        id: "9f8c2b41a", fromNumber: "2015550123", toNumber: "2125550123",
        status: "queued", documents: [{ name: "contract.pdf", size: 26, contentType: "application/pdf" }]
      )
    end

    it "POSTs a multipart form with a UUID v4 Idempotency-Key" do
      captured = nil
      stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/faxes")
        .with { |req| captured = req }
        .to_return(status: 201, body: job_envelope)

      result = client.fax.send_fax(
        from_number: "2015550123", to_number: "2125550123",
        documents: [{ name: "contract.pdf", content: pdf, content_type: "application/pdf" }]
      )
      expect(result).to be_a(VoiceTel::Models::FaxSendData)
      expect(result.id).to eq("9f8c2b41a")
      expect(result.status).to eq("queued")
      expect(result.documents.first).to be_a(VoiceTel::Models::FaxDocumentMeta)
      expect(result.documents.first.content_type).to eq("application/pdf")

      headers = captured.headers
      expect(headers["Content-Type"]).to match(%r{\Amultipart/form-data; boundary=})
      expect(headers["Idempotency-Key"]).to match(/\A\h{8}-\h{4}-4\h{3}-[89ab]\h{3}-\h{12}\z/)

      boundary = headers["Content-Type"].split("boundary=").last
      body = captured.body
      expect(body).to start_with("--#{boundary}\r\n")
      expect(body).to end_with("--#{boundary}--\r\n")
      expect(body).to include("Content-Disposition: form-data; name=\"fromNumber\"\r\n\r\n2015550123\r\n")
      expect(body).to include("Content-Disposition: form-data; name=\"toNumber\"\r\n\r\n2125550123\r\n")
      expect(body).to include("Content-Disposition: form-data; name=\"documents\"; filename=\"contract.pdf\"\r\n")
      expect(body).to include("Content-Type: application/pdf\r\n\r\n#{pdf}\r\n")
    end

    it "repeats the documents part for multiple documents and guesses the content type" do
      captured = nil
      stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/faxes")
        .with { |req| captured = req }
        .to_return(status: 201, body: job_envelope)

      client.fax.send_fax(
        from_number: "2015550123", to_number: "2125550123",
        documents: [{ name: "a.pdf", content: "pdf-a" }, { name: "b.docx", content: "docx-b" }]
      )
      body = captured.body
      expect(body.scan(%r{form-data; name="documents"}).length).to eq(2)
      expect(body).to include("filename=\"a.pdf\"\r\nContent-Type: application/pdf\r\n\r\npdf-a\r\n")
      expect(body).to include("filename=\"b.docx\"\r\n") # docx type guessed
      expect(body).to include("Content-Type: application/vnd.openxmlformats-officedocument.wordprocessingml.document\r\n\r\ndocx-b\r\n")
    end

    it "accepts bare file paths as documents" do
      captured = nil
      stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/faxes")
        .with { |req| captured = req }
        .to_return(status: 201, body: job_envelope)

      file = Tempfile.new(["voicetel-fax", ".pdf"])
      file.binmode
      file.write("path-pdf-bytes")
      file.close
      basename = File.basename(file.path)
      begin
        client.fax.send_fax(from_number: "2015550123", to_number: "2125550123", documents: [file.path])
      ensure
        file.unlink
      end
      body = captured.body
      expect(body).to include("filename=\"#{basename}\"\r\n")
      expect(body).to include("Content-Type: application/pdf\r\n\r\npath-pdf-bytes\r\n")
    end

    it "honors a caller-supplied idempotency key" do
      key = "123e4567-e89b-42d3-a456-426614174000"
      stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/faxes")
        .with(headers: { "Idempotency-Key" => key })
        .to_return(status: 201, body: job_envelope)
      client.fax.send_fax(
        from_number: "2015550123", to_number: "2125550123",
        documents: [{ name: "contract.pdf", content: pdf }],
        idempotency_key: key
      )
    end

    it "parses the fax error envelope's serverTime without breaking" do
      stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/faxes")
        .to_return(
          status: 429,
          headers: { "Retry-After" => "60" },
          body: {
            status: "error",
            error: { code: 429, message: "Too many faxes. Please wait a minute and try again." },
            serverTime: 1_795_100_000
          }.to_json
        )
      expect do
        client.fax.send_fax(from_number: "2015550123", to_number: "2125550123",
                            documents: [{ name: "contract.pdf", content: pdf }])
      end.to raise_error(VoiceTel::ApiError) do |e|
        expect(e.rate_limit?).to be(true)
        expect(e.message).to include("Too many faxes")
        expect(e.body["serverTime"]).to eq(1_795_100_000)
      end
    end

    it "maps 402 to insufficient_balance and 413 to payload_too_large" do
      {
        402 => [:insufficient_balance?, "Insufficient balance to send fax."],
        413 => [:payload_too_large?, "Document exceeds the 8 MiB limit."]
      }.each do |status, (predicate, message)|
        stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/faxes")
          .to_return(
            status: status,
            body: { status: "error", error: { code: status, message: message } }.to_json
          )
        expect do
          client.fax.send_fax(from_number: "2015550123", to_number: "2125550123",
                              documents: [{ name: "contract.pdf", content: pdf }])
        end.to raise_error(VoiceTel::ApiError) do |e|
          expect(e.kind).to eq(predicate.to_s.chomp("?").to_sym)
          expect(e.public_send(predicate)).to be(true)
          expect(e.status_code).to eq(status)
          expect(e.message).to include(message)
        end
      end
    end
  end

  describe "#history" do
    it "GETs /v2.2/faxes with the exact query names" do
      stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/faxes")
        .with(query: { "number" => "2015550123", "from" => "1795100000", "to" => "1795013600",
                       "limit" => "100", "cursor" => "cur.1", "status" => "failed" })
        .to_return(status: 200, body: envelope(
          number: "2015550123", fromTs: 1_795_100_000, toTs: 1_795_013_600,
          faxes: [{ id: "9f8c2b41a", status: "failed", failureReason: "no answer" }],
          nextCursor: nil
        ))
      result = client.fax.history(number: "2015550123", from: 1_795_100_000, to: 1_795_013_600,
                                  limit: 100, cursor: "cur.1", status: "failed")
      expect(result).to be_a(VoiceTel::Models::FaxHistoryData)
      expect(result.faxes.first).to be_a(VoiceTel::Models::FaxJob)
      expect(result.faxes.first.failure_reason).to eq("no answer")
      expect(result.next_cursor).to be_nil
    end

    it "sends only the required param by default" do
      stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/faxes")
        .with(query: { "number" => "2015550123" })
        .to_return(status: 200, body: envelope(number: "2015550123", faxes: [], nextCursor: nil))
      client.fax.history(number: "2015550123")
    end
  end

  describe "#get" do
    it "GETs /v2.2/faxes/{id} and builds a FaxJob" do
      stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/faxes/9f8c2b41a")
        .to_return(status: 200, body: envelope(
          id: "9f8c2b41a", fromNumber: "2015550123", toNumber: "2125550123",
          clientToken: "123e4567-e89b-42d3-a456-426614174000", status: "sent",
          submittedAt: "2026-11-20T15:04:05Z", startedAt: "2026-11-20T15:04:41Z",
          completedAt: "2026-11-20T15:05:19Z", attempts: 1, failureReason: nil,
          documents: [{ name: "contract.pdf", size: 123_456, contentType: "application/pdf" }],
          documentAvailable: true, documentName: "contract.pdf", documentSize: 123_456
        ))
      job = client.fax.get("9f8c2b41a")
      expect(job).to be_a(VoiceTel::Models::FaxJob)
      expect(job.status).to eq("sent")
      expect(job.submitted_at).to eq("2026-11-20T15:04:05Z")
      expect(job.document_available).to be(true)
      expect(job.documents.first.size).to eq(123_456)
    end
  end

  describe "#document" do
    it "GETs /v2.2/faxes/{id}/document and returns the raw PDF bytes" do
      stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/faxes/9f8c2b41a/document")
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/pdf",
                     "Content-Disposition" => 'attachment; filename="contract.pdf"' },
          body: pdf
        )
      bytes = client.fax.document("9f8c2b41a")
      expect(bytes).to eq(pdf)
      expect(bytes).to be_a(String)
    end

    it "maps a missing document to not_found" do
      stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/faxes/9f8c2b41a/document")
        .to_return(
          status: 404,
          body: { status: "error", error: { code: 404, message: "Not found" }, serverTime: 1_795_100_000 }.to_json
        )
      expect { client.fax.document("9f8c2b41a") }.to raise_error(VoiceTel::ApiError) do |e|
        expect(e.not_found?).to be(true)
      end
    end
  end
end
