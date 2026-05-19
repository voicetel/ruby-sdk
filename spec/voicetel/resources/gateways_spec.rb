# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::Gateways do
  let(:client) { new_client }

  it "GETs the gateway list" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/gateways")
      .to_return(status: 200, body: envelope(gateways: []))
    client.gateways.list
  end

  it "POSTs to add" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/gateways")
      .with(body: { gateway: "1.2.3.4", limit: 50 }.to_json)
      .to_return(status: 200, body: envelope(id: 1))
    client.gateways.add(gateway: "1.2.3.4", limit: 50)
  end

  it "GETs by id" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/gateways/7")
      .to_return(status: 200, body: envelope(id: 7))
    client.gateways.get(7)
  end

  it "PUTs an update" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/gateways/7")
      .with(body: { gateway: "2.3.4.5" }.to_json)
      .to_return(status: 200, body: envelope(id: 7))
    client.gateways.update(7, gateway: "2.3.4.5")
  end

  it "DELETEs (returns nil on 204)" do
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/gateways/7")
      .to_return(status: 204, body: "")
    expect(client.gateways.remove(7)).to be_nil
  end

  it "GETs bound numbers" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/gateways/7/numbers")
      .to_return(status: 200, body: envelope(numbers: []))
    client.gateways.numbers(7)
  end

  it "raises on 400" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/gateways")
      .to_return(status: 400, body: { message: "bad" }.to_json)
    expect { client.gateways.add(gateway: "x") }.to raise_error(VoiceTel::ApiError) { |e| expect(e.bad_request?).to be(true) }
  end
end
