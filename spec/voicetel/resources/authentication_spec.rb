# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::Authentication do
  let(:client) { new_client }

  it "GETs current auth mode" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/auth")
      .to_return(status: 200, body: envelope(authType: 0, authTypeDescription: "Digest", acl: []))
    result = client.authentication.get
    expect(result).to be_a(VoiceTel::Models::AuthGetData)
    expect(result.auth_type).to eq(0)
    expect(result.auth_type_description).to eq("Digest")
  end

  it "PUTs an auth update" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/auth")
      .with(body: { authType: 2 }.to_json)
      .to_return(status: 200, body: envelope(updated: [{ field: "authType", value: 2 }]))
    result = client.authentication.update(auth_type: 2)
    expect(result.updated.first).to be_a(VoiceTel::Models::AuthUpdatedEntry)
    expect(result.updated.first.value).to eq(2)
  end

  it "exposes the four auth-type constants (0=Digest, 1=Lax, 2=IP, 3=Strict)" do
    expect(described_class::AUTH_TYPE_DIGEST).to eq(0)
    expect(described_class::AUTH_TYPE_LAX).to eq(1)
    expect(described_class::AUTH_TYPE_IP).to eq(2)
    expect(described_class::AUTH_TYPE_STRICT).to eq(3)
  end

  it "raises on 409" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/auth")
      .to_return(status: 409, body: { message: "no change" }.to_json)
    expect { client.authentication.update(auth_type: 0) }.to raise_error(VoiceTel::ApiError, /HTTP 409/)
  end
end
