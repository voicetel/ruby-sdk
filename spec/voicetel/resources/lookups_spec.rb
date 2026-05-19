# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::Lookups do
  let(:client) { new_client }

  it "GETs CNAM" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/cnam/2015551234")
      .to_return(status: 200, body: envelope(cnam: "ACME INC", number: "2015551234"))
    expect(client.lookups.cnam("2015551234")["cnam"]).to eq("ACME INC")
  end

  it "GETs LRN" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/lrn/2015551234/2012548000")
      .to_return(status: 200, body: envelope(ani: "2012548000", destination: "2015551234", lrn: { lrn: "2015552000" }))
    expect(client.lookups.lrn("2015551234", "2012548000")["lrn"]["lrn"]).to eq("2015552000")
  end

  it "raises on 404" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/cnam/0000000000")
      .to_return(status: 404, body: { message: "not found" }.to_json)
    expect { client.lookups.cnam("0000000000") }.to raise_error(VoiceTel::ApiError) { |e| expect(e.not_found?).to be(true) }
  end
end
