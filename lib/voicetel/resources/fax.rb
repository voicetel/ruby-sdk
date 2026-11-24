# frozen_string_literal: true

require "securerandom"

require_relative "base"

module VoiceTel
  module Resources
    # Fax — sends faxes from the account's fax-capable numbers and reads
    # their job history and rendered documents.
    #
    # send_fax posts a multipart form and is idempotent per the
    # client-generated UUID Idempotency-Key: resubmitting the same
    # documents with the same key returns the original job instead of
    # sending twice. Limited to 10 sends per minute per account.
    class Fax < Base
      # Extension → MIME type for the accepted fax document types
      # (PDF/DOC/DOCX; the server checks content, not extension).
      CONTENT_TYPES = {
        "pdf" => "application/pdf",
        "doc" => "application/msword",
        "docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      }.freeze

      # GET /v2.2/numbers/fax — every fax-capable number on the account,
      # with the email address faxes to each number deliver to
      # (destination_id 0 = the account email).
      #
      # @return [Models::FaxNumbersData]
      def numbers
        Models::FaxNumbersData.build(@transport.request(:get, "/v2.2/numbers/fax"))
      end

      # POST /v2.2/faxes — submit a fax for delivery (HTTP 201, queued).
      #
      # @param from_number [String] fax number on this account, 10 digits
      # @param to_number [String] US/CA destination, 10 digits
      # @param documents [Array<Hash, String>] one to ten documents — each
      #   either a part Hash ({ name:, content: raw bytes, content_type:
      #   optional — guessed from the name when omitted }) or a bare file
      #   path
      # @param idempotency_key [String, nil] client-generated UUID; a fresh
      #   one is generated when omitted. Pass the same key with the same
      #   documents to get the original job back instead of a second send.
      # @return [Models::FaxSendData]
      def send_fax(from_number:, to_number:, documents:, idempotency_key: nil)
        Models::FaxSendData.build(@transport.request(
                                    :post, "/v2.2/faxes",
                                    multipart: {
                                      fields: { "fromNumber" => from_number, "toNumber" => to_number },
                                      files: documents.map { |document| document_part(document) }
                                    },
                                    idempotency_key: idempotency_key || SecureRandom.uuid
                                  ))
      end

      # GET /v2.2/faxes — history for one fax number, newest first.
      #
      # @param number [String] a fax number on the account (required)
      # @param from [Integer, nil] newer edge of the range, unix seconds (defaults to now)
      # @param to [Integer, nil] older edge of the range, unix seconds (defaults to 24h ago)
      # @param limit [Integer, nil] page size, 1..100 (defaults to 50)
      # @param cursor [String, nil] paging cursor from a previous next_cursor
      # @param status [String, nil] all|active|queued|sending|retry_pending|sent|failed
      # @return [Models::FaxHistoryData]
      def history(number:, from: nil, to: nil, limit: nil, cursor: nil, status: nil)
        q = compact_query(
          "number" => number,
          "from" => from,
          "to" => to,
          "limit" => limit,
          "cursor" => cursor,
          "status" => status
        )
        Models::FaxHistoryData.build(@transport.request(:get, "/v2.2/faxes", query: q))
      end

      # GET /v2.2/faxes/{id} — one fax job. Poll until status is "sent" or
      # "failed".
      #
      # @return [Models::FaxJob]
      def get(id)
        Models::FaxJob.build(@transport.request(:get, "/v2.2/faxes/#{escape_path(id)}"))
      end

      # GET /v2.2/faxes/{id}/document — the rendered PDF as raw bytes
      # (binary response, not parsed). Served when the job reports
      # document_available true; 404 otherwise.
      #
      # @return [String]
      def document(id)
        @transport.request(:get, "/v2.2/faxes/#{escape_path(id)}/document", raw: true)
      end

      private

      # Normalize one documents argument into a multipart file part.
      def document_part(document)
        document = { name: File.basename(document), content: File.binread(document) } if document.is_a?(String)
        ext = File.extname(document[:name].to_s).delete_prefix(".").downcase
        {
          name: "documents",
          filename: document[:name],
          content: document[:content],
          content_type: document[:content_type] || CONTENT_TYPES.fetch(ext, "application/octet-stream")
        }
      end
    end
  end
end
