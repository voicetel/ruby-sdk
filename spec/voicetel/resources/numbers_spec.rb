# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::Numbers do
  let(:client) { new_client }

  it "lists all numbers" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers").to_return(status: 200, body: envelope(numbers: []))
    client.numbers.list
  end

  it "adds a number" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/numbers")
      .with(body: { number: "2015551234", route: 4 }.to_json)
      .to_return(status: 200, body: envelope(number: "2015551234", route: 4))
    client.numbers.add(number: "2015551234", route: 4)
  end

  it "GETs one number" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234").to_return(status: 200, body: envelope(number: "2015551234"))
    client.numbers.get("2015551234")
  end

  it "removes a number (204)" do
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234").to_return(status: 204, body: "")
    expect(client.numbers.remove("2015551234")).to be_nil
  end

  it "moves a number (PATCH)" do
    stub_request(:patch, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234")
      .with(body: { accountId: 2, route: 4 }.to_json)
      .to_return(status: 200, body: envelope(number: "2015551234"))
    client.numbers.move("2015551234", account_id: 2, route: 4)
  end

  it "releases a number" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/release").to_return(status: 204, body: "")
    expect(client.numbers.release("2015551234")).to be_nil
  end

  it "sets route" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/route")
      .with(body: { route: 5 }.to_json).to_return(status: 200, body: envelope(number: "2015551234", route: 5))
    client.numbers.set_route("2015551234", route: 5)
  end

  it "sets translation" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/translation")
      .with(body: { translation: "100" }.to_json).to_return(status: 200, body: envelope(translation: "100"))
    client.numbers.set_translation("2015551234", translation: "100")
  end

  it "sets cnam" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/cnam")
      .with(body: { enabled: true }.to_json).to_return(status: 200, body: envelope(cnam: true))
    client.numbers.set_cnam("2015551234", enabled: true)
  end

  it "sets lidb" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/lidb")
      .with(body: { cnam: "ACME" }.to_json).to_return(status: 200, body: envelope(cnam: "ACME"))
    client.numbers.set_lidb("2015551234", cnam: "ACME")
  end

  it "gets/sets/removes fax" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/fax").to_return(status: 200, body: envelope(email: "a@b"))
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/fax").to_return(status: 200, body: envelope(email: "a@b"))
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/fax").to_return(status: 204, body: "")
    client.numbers.get_fax("2015551234")
    client.numbers.set_fax("2015551234", email: "a@b")
    expect(client.numbers.remove_fax("2015551234")).to be_nil
  end

  it "sets/removes forward" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/forward").to_return(status: 200, body: envelope(forwardTo: "2"))
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/forward").to_return(status: 204, body: "")
    client.numbers.set_forward("2015551234", destination: 2_125_551_234)
    expect(client.numbers.remove_forward("2015551234")).to be_nil
  end

  it "gets/sets/removes sms" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/sms").to_return(status: 200, body: envelope(type: "email"))
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/sms").to_return(status: 200, body: envelope(type: "email"))
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/sms").to_return(status: 204, body: "")
    client.numbers.get_sms("2015551234")
    client.numbers.set_sms("2015551234", type: "email", resource: "a@b")
    expect(client.numbers.remove_sms("2015551234")).to be_nil
  end

  it "gets/patches messaging state" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/messaging").to_return(status: 200, body: envelope(enabled: true))
    stub_request(:patch, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/messaging").to_return(status: 200,
                                                                                                 body: envelope(updated: ["routeIn"]))
    client.numbers.get_messaging("2015551234")
    client.numbers.patch_messaging("2015551234", route_in: 1)
  end

  it "assigns and unassigns a campaign (DELETE returns 200 + body, not 204)" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/messaging-campaign")
      .with(body: { campaignId: "CABC123" }.to_json)
      .to_return(status: 200, body: envelope(campaignId: "CABC123"))
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/messaging-campaign")
      .to_return(status: 200, body: envelope(unassigned: true))

    client.numbers.assign_campaign("2015551234", campaign_id: "CABC123")
    expect(client.numbers.unassign_campaign("2015551234")).to eq("unassigned" => true)
  end

  it "bulk-unassigns campaigns (DELETE returns 200 + body)" do
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/numbers/messaging-campaign")
      .with(body: { numbers: %w[2015551234 2015551235] }.to_json)
      .to_return(status: 200, body: envelope(unassignedNumbers: %w[2015551234 2015551235]))
    expect(client.numbers.bulk_unassign_campaign(%w[2015551234 2015551235]))
      .to eq("unassignedNumbers" => %w[2015551234 2015551235])
  end

  it "sets port-out PIN" do
    stub_request(:patch, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234/port-out-pin")
      .with(body: { pin: "1234" }.to_json)
      .to_return(status: 200, body: envelope(portOutPin: "1234"))
    client.numbers.set_port_out_pin("2015551234", pin: "1234")
  end

  it "raises on 403 permission denied" do
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015551234")
      .to_return(status: 403, body: { message: "denied" }.to_json)
    expect { client.numbers.remove("2015551234") }.to raise_error(VoiceTel::ApiError) { |e| expect(e.permission_denied?).to be(true) }
  end
end
