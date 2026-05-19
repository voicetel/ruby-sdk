# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::INumbering do
  let(:client) { new_client }

  it "searches inventory with all filters" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/inventory")
      .with(query: { npa: 201, nxx: 555, state: "NJ", ratecenter: "NEWARK", contains: "1212", endswith: "00", limit: 5 })
      .to_return(status: 200, body: envelope(numbers: []))
    client.i_numbering.search_inventory(npa: 201, nxx: 555, state: "NJ", ratecenter: "NEWARK", contains: "1212", endswith: "00", limit: 5)
  end

  it "searches inventory with no filters" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/inventory")
      .to_return(status: 200, body: envelope(numbers: []))
    client.i_numbering.search_inventory
  end

  it "GETs coverage" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/inventory/coverage")
      .with(query: { state: "NJ" })
      .to_return(status: 200, body: envelope(coverage: []))
    client.i_numbering.coverage(state: "NJ")
  end

  it "POSTs an order" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/orders")
      .with(body: { numbers: ["2015551234"] }.to_json)
      .to_return(status: 200, body: envelope(orderId: "O123"))
    client.i_numbering.order(numbers: ["2015551234"])
  end

  it "GETs port list" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/ports")
      .to_return(status: 200, body: envelope(ports: []))
    client.i_numbering.ports
  end

  it "GETs one port detail" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/ports/9")
      .to_return(status: 200, body: envelope(port: { id: "9" }))
    client.i_numbering.port(9)
  end

  it "POSTs a port submission" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/ports")
      .to_return(status: 200, body: envelope(pid: "ABCDE", ticket: 1, message: "ok", loaUrl: "", portUrl: ""))
    client.i_numbering.submit_port(did: ["2015551234"], name: "X")
  end

  it "GETs port availability and includes v2.2.10 LRN + rate_center_tier fields" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/ports/availability/2015551234")
      .to_return(status: 200, body: envelope(
        number: "2015551234",
        portable: true,
        losingCarrier: "AT&T",
        localRoutingNumber: "2015551200",
        rateCenterTier: "tier1",
        reason: nil
      ))
    result = client.i_numbering.port_availability("2015551234")
    expect(result).to include("number" => "2015551234", "portable" => true, "localRoutingNumber" => "2015551200",
                              "rateCenterTier" => "tier1")
  end

  it "raises on 400 invalid query" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/inventory")
      .with(query: { npa: 99 })
      .to_return(status: 400, body: { message: "bad npa" }.to_json)
    expect { client.i_numbering.search_inventory(npa: 99) }.to raise_error(VoiceTel::ApiError) { |e| expect(e.bad_request?).to be(true) }
  end
end
