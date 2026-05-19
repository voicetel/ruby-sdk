# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::E911 do
  let(:client) { new_client }

  it "GETs the e911 list" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/e911")
      .to_return(status: 200, body: envelope(records: []))
    client.e911.list
  end

  it "POSTs to create" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/e911")
      .to_return(status: 200, body: envelope(record: { dn: "12015551234" }))
    client.e911.create(dn: "2015551234", callername: "X", address1: "1 Main", city: "Newark", state: "NJ", zip: "07101")
  end

  it "POSTs to validate" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/e911/validations")
      .to_return(status: 200, body: envelope(address: { addressid: 42 }))
    client.e911.validate(address1: "1", city: "Newark", state: "NJ", zip: "07101")
  end

  it "GETs by dn" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/e911/2015551234")
      .to_return(status: 200, body: envelope(record: { dn: "12015551234" }))
    client.e911.get("2015551234")
  end

  it "PUTs provision by dn" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/e911/2015551234")
      .with(body: { callername: "X", addressid: 42 }.to_json)
      .to_return(status: 200, body: envelope(record: { dn: "12015551234" }))
    client.e911.provision("2015551234", callername: "X", addressid: 42)
  end

  it "DELETE returns nil on 204" do
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/e911/2015551234")
      .to_return(status: 204, body: "")
    expect(client.e911.remove("2015551234")).to be_nil
  end

  it "raises on 404 from GET" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/e911/2015550000")
      .to_return(status: 404, body: { message: "no record" }.to_json)
    expect { client.e911.get("2015550000") }.to raise_error(VoiceTel::ApiError) { |e| expect(e.not_found?).to be(true) }
  end
end
