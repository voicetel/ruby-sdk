# frozen_string_literal: true

# Read-only integration tests against api.voicetel.com.
#
# Gated by VOICETEL_USERNAME / VOICETEL_PASSWORD env vars. RSpec's
# `:integration` tag is excluded by default in spec_helper.rb — set
# INTEGRATION=1 to include this suite.
#
# These tests are deliberately limited to GETs. They share the 6 req/hour/IP
# rate limit on account/* endpoints, so don't run them in a tight loop.

RSpec.describe VoiceTel::Client, :integration do
  let(:username) { ENV.fetch("VOICETEL_USERNAME", nil) }
  let(:password) { ENV.fetch("VOICETEL_PASSWORD", nil) }
  let(:base_url) { ENV["VOICETEL_BASE_URL"] || "https://api.voicetel.com" }

  before do
    # Secrets arrive as empty strings when unset, so treat "" as absent too.
    skip "VOICETEL_USERNAME / VOICETEL_PASSWORD not set" if username.to_s.empty? || password.to_s.empty?
    WebMock.allow_net_connect!
  end

  after { WebMock.disable_net_connect!(allow_localhost: false) }

  it "logs in and reads the account profile" do
    client = described_class.new(base_url: base_url)
    key = client.login(username: Integer(username), password: password)
    expect(key).to match(/\A[a-f0-9]{32}\z/i)

    me = client.account.get
    expect(me).to be_a(VoiceTel::Models::AccountData)
    expect(me.username).to be_truthy
  end

  it "lists numbers without raising" do
    client = described_class.new(base_url: base_url)
    client.login(username: Integer(username), password: password)
    result = client.numbers.list
    expect(result).to be_a(VoiceTel::Models::NumbersListData)
    expect(result.numbers).to be_an(Array)
  end
end
