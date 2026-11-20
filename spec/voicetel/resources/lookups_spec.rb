# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::Lookups do
  let(:client) { new_client }

  it "GETs CNAM" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/cnam/2015550123")
      .to_return(status: 200, body: envelope(cnam: "ACME INC", number: "2015550123"))
    result = client.lookups.cnam("2015550123")
    expect(result).to be_a(VoiceTel::Models::CnamData)
    expect(result.cnam).to eq("ACME INC")
  end

  it "GETs LRN" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/lrn/2015550123/2015550100")
      .to_return(status: 200, body: envelope(ani: "2015550100", destination: "2015550123",
                                             lrn: { lrn: "2015552000", state: "NJ" }))
    result = client.lookups.lrn("2015550123", "2015550100")
    expect(result).to be_a(VoiceTel::Models::LrnLookupData)
    expect(result.lrn).to be_a(VoiceTel::Models::LrnData)
    expect(result.lrn.lrn).to eq("2015552000")
  end

  it "GETs carrier details with the upstream snake_case field names" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/carrier/2015550123")
      .to_return(
        status: 200,
        body: envelope(number: "2015550123",
                       carrier: { name: "EXAMPLE CARRIER", type: "voip",
                                  mobile_country_code: nil, mobile_network_code: nil,
                                  error_code: nil })
      )
    result = client.lookups.carrier("2015550123")
    expect(result).to be_a(VoiceTel::Models::CarrierData)
    expect(result.number).to eq("2015550123")
    expect(result.carrier).to be_a(VoiceTel::Models::CarrierDetails)
    expect(result.carrier.name).to eq("EXAMPLE CARRIER")
    expect(result.carrier.type).to eq("voip")
    expect(result.carrier.mobile_country_code).to be_nil
    expect(result.carrier.mobile_network_code).to be_nil
    expect(result.carrier.error_code).to be_nil
  end

  it "reads mobile carrier fields" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/carrier/2015550123")
      .to_return(
        status: 200,
        body: envelope(number: "2015550123",
                       carrier: { name: "EXAMPLE MOBILE", type: "mobile",
                                  mobile_country_code: "310", mobile_network_code: "456",
                                  error_code: nil })
      )
    result = client.lookups.carrier("2015550123")
    expect(result.carrier.mobile_country_code).to eq("310")
    expect(result.carrier.mobile_network_code).to eq("456")
  end

  it "raises on 404" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/cnam/0000000000")
      .to_return(status: 404, body: { message: "not found" }.to_json)
    expect { client.lookups.cnam("0000000000") }.to raise_error(VoiceTel::ApiError) { |e| expect(e.not_found?).to be(true) }
  end
end
