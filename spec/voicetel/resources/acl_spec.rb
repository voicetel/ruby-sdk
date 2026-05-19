# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::Acl do
  let(:client) { new_client }

  it "GETs the allowlist" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/acl")
      .to_return(status: 200, body: envelope(acl: [{ cidr: "1.2.3.0/24" }]))
    expect(client.acl.list).to eq("acl" => [{ "cidr" => "1.2.3.0/24" }])
  end

  it "POSTs to add CIDR entries" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/acl")
      .with(body: { acl: [{ cidr: "1.2.3.0/24" }] }.to_json)
      .to_return(status: 200, body: envelope(added: [{ cidr: "1.2.3.0/24" }]))
    client.acl.add(acl: [{ cidr: "1.2.3.0/24" }])
  end

  it "DELETEs CIDR entries (returns 200 with a body)" do
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/acl")
      .with(body: { acl: [{ cidr: "1.2.3.0/24" }] }.to_json)
      .to_return(status: 200, body: envelope(removed: [{ cidr: "1.2.3.0/24" }]))
    expect(client.acl.remove(acl: [{ cidr: "1.2.3.0/24" }]))
      .to eq("removed" => [{ "cidr" => "1.2.3.0/24" }])
  end

  it "surfaces the 409 conflict body via ApiError#body" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/acl")
      .to_return(
        status: 409,
        body: { added: [], failed: [{ cidr: "1.2.3.0/30", reason: "Invalid mask: must be /8, /16, /24, or /32" }] }.to_json
      )
    expect { client.acl.add(acl: [{ cidr: "1.2.3.0/30" }]) }.to raise_error(VoiceTel::ApiError) do |e|
      expect(e.conflict?).to be(true)
      expect(e.body["failed"].first["cidr"]).to eq("1.2.3.0/30")
    end
  end
end
