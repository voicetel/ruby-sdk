# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::Acl do
  let(:client) { new_client }

  it "GETs the allowlist" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/acl")
      .to_return(status: 200, body: envelope(acl: [{ cidr: "1.2.3.0/24" }]))
    result = client.acl.list
    expect(result).to be_a(VoiceTel::Models::AclListData)
    expect(result.acl.first).to be_a(VoiceTel::Models::CidrEntry)
    expect(result.acl.first.cidr).to eq("1.2.3.0/24")
  end

  it "POSTs to add CIDR entries" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/acl")
      .with(body: { acl: [{ cidr: "1.2.3.0/24" }] }.to_json)
      .to_return(status: 200, body: envelope(added: [{ cidr: "1.2.3.0/24" }]))
    result = client.acl.add(acl: [{ cidr: "1.2.3.0/24" }])
    expect(result.added.first.cidr).to eq("1.2.3.0/24")
  end

  it "serializes CidrEntry request models in the body" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/acl")
      .with(body: { acl: [{ cidr: "1.2.3.0/24" }] }.to_json)
      .to_return(status: 200, body: envelope(added: [{ cidr: "1.2.3.0/24" }]))
    client.acl.add(VoiceTel::Models::AclModifyRequest.new(
                     acl: [VoiceTel::Models::CidrEntry.new(cidr: "1.2.3.0/24")]
                   ))
  end

  it "DELETEs CIDR entries via the cidrs query param (returns 200 with a body)" do
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/acl")
      .with(query: { cidrs: "1.2.3.0/24" }) { |req| req.body.nil? || req.body.empty? }
      .to_return(status: 200, body: envelope(removed: [{ cidr: "1.2.3.0/24" }]))
    result = client.acl.remove(cidrs: ["1.2.3.0/24"])
    expect(result.removed.first.cidr).to eq("1.2.3.0/24")
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

  it "can build an AclConflictData from a 409 body" do
    conflict = VoiceTel::Models::AclConflictData.build(
      { "added" => [], "failed" => [{ "cidr" => "1.2.3.0/30", "reason" => "Invalid mask: must be /8, /16, /24, or /32" }] }
    )
    expect(conflict.failed.first).to be_a(VoiceTel::Models::AclFailedEntry)
    expect(conflict.failed.first.reason).to include("Invalid mask")
  end
end
