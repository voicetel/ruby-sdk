# frozen_string_literal: true

RSpec.describe VoiceTel do
  describe "module constants" do
    it "tracks the API version" do
      expect(described_class::VERSION).to eq("2.2.10")
      expect(described_class::API_VERSION).to eq("v2.2.10")
      expect(described_class::DEFAULT_BASE_URL).to eq("https://api.voicetel.com")
    end

    it "includes the SDK name in the user-agent" do
      expect(described_class::USER_AGENT).to include("voicetel-ruby")
      expect(described_class::USER_AGENT).to include(described_class::VERSION)
    end
  end

  describe VoiceTel::Client do
    it "constructs with an api_key and exposes the configured base url" do
      c = described_class.new(api_key: "abc", base_url: "https://example.test")
      expect(c.api_key).to eq("abc")
      expect(c.base_url).to eq("https://example.test")
    end

    it "defaults to the production base url when none is provided" do
      c = described_class.new(api_key: "abc")
      expect(c.base_url).to eq(VoiceTel::DEFAULT_BASE_URL)
    end

    it "exposes ten memoized resource accessors" do
      c = described_class.new(api_key: "abc")
      %i[account acl authentication e911 gateways i_numbering lookups messaging numbers support].each do |name|
        first = c.public_send(name)
        second = c.public_send(name)
        expect(first).to be(second)
      end
    end

    describe "#login" do
      let(:client) { described_class.new(base_url: SpecHelpers::BASE_URL, max_retries: 0) }

      it "exchanges credentials for an api key and installs it" do
        stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/account/api-key")
          .with(body: { username: 1_000_000_001, password: "hunter2" }.to_json)
          .to_return(
            status: 200,
            body: { status: "success", data: { apikey: "deadbeef" * 4 } }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        returned = client.login(username: 1_000_000_001, password: "hunter2")
        expect(returned).to eq("deadbeef" * 4)
        expect(client.api_key).to eq("deadbeef" * 4)
      end

      it "raises an authentication ApiError when the response omits the apikey" do
        stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/account/api-key")
          .to_return(
            status: 200,
            body: { status: "success", data: {} }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect { client.login(username: 1, password: "x") }.to raise_error(VoiceTel::ApiError) do |e|
          expect(e.kind).to eq(:authentication)
          expect(e.authentication?).to be(true)
        end
      end
    end
  end
end
