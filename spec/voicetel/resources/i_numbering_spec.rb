# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::INumbering do
  let(:client) { new_client }

  it "searches inventory with all filters" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/inventory")
      .with(query: { tnMask: "201555*", quantity: 5, province: "NJ", rateCenter: "NEWARK", lata: 224 })
      .to_return(status: 200, body: envelope(numbers: []))
    expect(client.i_numbering.search_inventory(tn_mask: "201555*", quantity: 5, province: "NJ",
                                               rate_center: "NEWARK", lata: 224))
      .to be_a(VoiceTel::Models::InventorySearchData)
  end

  it "searches inventory with only the required tn_mask" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/inventory")
      .with(query: { tnMask: "201" })
      .to_return(status: 200, body: envelope(numbers: []))
    client.i_numbering.search_inventory(tn_mask: "201")
  end

  it "GETs coverage" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/inventory/coverage")
      .with(query: { countBy: "state", locState: "NJ" })
      .to_return(status: 200, body: envelope(coverage: []))
    expect(client.i_numbering.coverage(count_by: "state", loc_state: "NJ")).to be_a(VoiceTel::Models::InventoryCoverageData)
  end

  it "POSTs an order and reports the amount charged" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/orders")
      .with(body: { numbers: ["2015550123"] }.to_json)
      .to_return(status: 200, body: envelope(orderId: "O123", amountCharged: 1.25,
                                             numbersOrdered: ["2015550123"], failed: []))
    result = client.i_numbering.order(numbers: ["2015550123"])
    expect(result).to be_a(VoiceTel::Models::OrderCreateData)
    expect(result.order_id).to eq("O123")
    expect(result.amount_charged).to eq(1.25)
    expect(result.numbers_ordered).to eq(["2015550123"])
  end

  it "serializes OrderNumberSpec entries inside an order body" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/orders")
      .with(body: { numbers: [{ number: "2015550123", route: 4 }] }.to_json)
      .to_return(status: 200, body: envelope(orderId: "O124", amountCharged: 1.25,
                                             numbersOrdered: ["2015550123"]))
    client.i_numbering.order(
      numbers: [VoiceTel::Models::OrderNumberSpec.new(number: "2015550123", route: 4)]
    )
  end

  it "GETs the port list without supportUrl (removed in API 2.2.11)" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/ports").to_return(
      status: 200,
      body: envelope(ports: [{ status: "Complete", id: "9", pid: "ABCDE", foc: "20261101",
                               createdAt: "2026-10-01T00:00:00Z", message: "ported" }])
    )
    result = client.i_numbering.ports
    expect(result).to be_a(VoiceTel::Models::PortListData)
    summary = result.ports.first
    expect(summary).to be_a(VoiceTel::Models::PortSummary)
    expect(summary.status).to eq("Complete")
    expect(summary).not_to respond_to(:support_url)
    expect(VoiceTel::Models::PortSummary.members).not_to include(:support_url)
  end

  it "GETs one port detail without supportUrl" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/ports/9").to_return(
      status: 200,
      body: envelope(port: { status: "Complete", id: "9", numbers: ["2015550123"] })
    )
    result = client.i_numbering.port("9")
    expect(result).to be_a(VoiceTel::Models::PortDetailData)
    expect(result.port).to be_a(VoiceTel::Models::PortDetail)
    expect(result.port).not_to respond_to(:support_url)
    expect(result.port.numbers).to eq(["2015550123"])
  end

  it "POSTs a port submission" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/ports")
      .to_return(status: 200, body: envelope(pid: "ABCDE", ticket: 1, message: "ok", loaUrl: "", portUrl: ""))
    result = client.i_numbering.submit_port(did: ["2015550123"], name: "X")
    expect(result).to be_a(VoiceTel::Models::PortSubmitData)
    expect(result.pid).to eq("ABCDE")
  end

  it "GETs port availability and includes v2.2.10 LRN + rate_center_tier fields" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/ports/availability/2015550123").to_return(
      status: 200,
      body: envelope(
        number: "2015550123",
        portable: true,
        losingCarrier: "AT&T",
        localRoutingNumber: "2015551200",
        rateCenterTier: "tier1",
        reason: nil
      )
    )
    result = client.i_numbering.port_availability("2015550123")
    expect(result).to be_a(VoiceTel::Models::PortAvailabilityData)
    expect(result.number).to eq("2015550123")
    expect(result.portable).to be(true)
    expect(result.local_routing_number).to eq("2015551200")
    expect(result.rate_center_tier).to eq("tier1")
  end

  it "raises on 400 invalid query" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/inventory")
      .with(query: { tnMask: "99" })
      .to_return(status: 400, body: { status: "error", error: { code: 400, message: "bad tnMask" } }.to_json)
    expect { client.i_numbering.search_inventory(tn_mask: "99") }.to raise_error(VoiceTel::ApiError) { |e| expect(e.bad_request?).to be(true) }
  end
end
