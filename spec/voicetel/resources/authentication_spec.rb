# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::Authentication do
  let(:client) { new_client }

  it "GETs current auth mode" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/auth")
      .to_return(status: 200, body: envelope(authType: 0, authTypeDescription: "Digest", acl: []))
    expect(client.authentication.get["authType"]).to eq(0)
  end

  it "PUTs an auth update" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/auth")
      .with(body: { authType: 1 }.to_json)
      .to_return(status: 200, body: envelope(updated: [{ field: "authType", value: 1 }]))
    client.authentication.update(auth_type: 1)
  end

  it "exposes the four auth-type constants" do
    expect(described_class::AUTH_TYPE_DIGEST).to eq(0)
    expect(described_class::AUTH_TYPE_IP).to eq(1)
    expect(described_class::AUTH_TYPE_DIGEST_OR_IP).to eq(2)
    expect(described_class::AUTH_TYPE_DIGEST_AND_IP).to eq(3)
  end

  it "raises on 409" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/auth")
      .to_return(status: 409, body: { message: "no change" }.to_json)
    expect { client.authentication.update(auth_type: 0) }.to raise_error(VoiceTel::ApiError, /HTTP 409/)
  end
end
