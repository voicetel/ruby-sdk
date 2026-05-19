# frozen_string_literal: true

RSpec.describe VoiceTel::Internal::Transport do
  let(:transport) do
    described_class.new(
      base_url: SpecHelpers::BASE_URL,
      api_key: SpecHelpers::API_KEY,
      max_retries: 0,
      timeout: 5
    )
  end

  describe "#camelize_keys" do
    it "leaves keys with no underscores alone" do
      expect(transport.camelize_keys({ "foo" => 1, bar: 2 })).to eq({ "foo" => 1, "bar" => 2 })
    end

    it "converts snake_case keys to camelCase" do
      input = { from_number: "201", to_number: "202", nested: { campaign_id: "X" } }
      output = transport.camelize_keys(input)
      expect(output).to eq({ "fromNumber" => "201", "toNumber" => "202", "nested" => { "campaignId" => "X" } })
    end

    it "recurses into arrays" do
      input = { items: [{ rate_center: "RC" }, { rate_center: "RC2" }] }
      expect(transport.camelize_keys(input)).to eq({ "items" => [{ "rateCenter" => "RC" }, { "rateCenter" => "RC2" }] })
    end

    it "passes through non-collection values" do
      expect(transport.camelize_keys("plain")).to eq("plain")
      expect(transport.camelize_keys(42)).to eq(42)
      expect(transport.camelize_keys(nil)).to be_nil
    end
  end

  describe "#request" do
    it "sends the Authorization header and parses the envelope" do
      stub = stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account")
             .with(headers: { "Authorization" => "Bearer #{SpecHelpers::API_KEY}" })
             .to_return(
               status: 200,
               body: { status: "success", data: { cash: 4.20 } }.to_json,
               headers: { "Content-Type" => "application/json" }
             )

      result = transport.request(:get, "/v2.2/account")
      expect(result).to eq("cash" => 4.20)
      expect(stub).to have_been_requested
    end

    it "camelizes body keys when serializing JSON" do
      stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/messages")
        .with(body: { fromNumber: "2012548000", toNumber: "2015551234", text: "hi" }.to_json)
        .to_return(status: 200, body: { status: "success", data: { id: "abc" } }.to_json)

      transport.request(:post, "/v2.2/messages", body: { from_number: "2012548000", to_number: "2015551234", text: "hi" })
    end

    it "camelizes query params when given as snake_case" do
      stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/inventory?rateCenter=Newark&state=NJ")
        .to_return(status: 200, body: { status: "success", data: { numbers: [] } }.to_json)

      transport.request(:get, "/v2.2/inventory", query: { "state" => "NJ", "rate_center" => "Newark" })
    end

    it "returns nil on 204 No Content" do
      stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234")
        .to_return(status: 204, body: "")

      expect(transport.request(:delete, "/v2.2/numbers/2015551234")).to be_nil
    end

    it "returns the parsed body untouched when there is no envelope" do
      stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/raw")
        .to_return(status: 200, body: '{"plain":"ok"}')

      expect(transport.request(:get, "/v2.2/raw")).to eq("plain" => "ok")
    end

    it "raises an authentication ApiError when no api key is set and auth is required" do
      t = described_class.new(base_url: SpecHelpers::BASE_URL, api_key: nil, max_retries: 0)
      expect { t.request(:get, "/v2.2/account") }.to raise_error(VoiceTel::ApiError) do |e|
        expect(e.kind).to eq(:authentication)
      end
    end

    it "skips the Authorization header when require_auth is false" do
      stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/account/recovery")
        .with { |req| !req.headers.key?("Authorization") }
        .to_return(status: 200, body: { status: "success", data: { message: "ok" } }.to_json)

      t = described_class.new(base_url: SpecHelpers::BASE_URL, api_key: nil, max_retries: 0)
      result = t.request(:post, "/v2.2/account/recovery", body: { email: "x@y" }, require_auth: false)
      expect(result).to eq("message" => "ok")
    end

    it "raises an ApiError with the correct kind on 404" do
      stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers/9999999999")
        .to_return(
          status: 404,
          body: { code: "ENOENT", message: "no such number" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { transport.request(:get, "/v2.2/numbers/9999999999") }.to raise_error(VoiceTel::ApiError) do |e|
        expect(e.kind).to eq(:not_found)
        expect(e.status_code).to eq(404)
        expect(e.code).to eq("ENOENT")
        expect(e.body).to eq("code" => "ENOENT", "message" => "no such number")
      end
    end

    it "raises a rate_limit ApiError on 429" do
      stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account/cdr")
        .to_return(status: 429, body: { message: "slow down" }.to_json)

      expect { transport.request(:get, "/v2.2/account/cdr") }.to raise_error(VoiceTel::ApiError) do |e|
        expect(e.rate_limit?).to be(true)
      end
    end

    it "raises a server ApiError on 500 with a plain-text body" do
      stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/anywhere")
        .to_return(status: 500, body: "boom")

      expect { transport.request(:get, "/v2.2/anywhere") }.to raise_error(VoiceTel::ApiError) do |e|
        expect(e.server?).to be(true)
        expect(e.body).to eq("boom")
      end
    end

    it "raises a connection error when faraday cannot reach the host" do
      stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/anywhere")
        .to_raise(Faraday::ConnectionFailed.new("getaddrinfo"))

      expect { transport.request(:get, "/v2.2/anywhere") }.to raise_error(VoiceTel::ApiError, /connection failed/)
    end

    it "raises a timeout error when faraday times out" do
      stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/anywhere")
        .to_raise(Faraday::TimeoutError.new("execution expired"))

      expect { transport.request(:get, "/v2.2/anywhere") }.to raise_error(VoiceTel::ApiError, /timed out/)
    end
  end
end
