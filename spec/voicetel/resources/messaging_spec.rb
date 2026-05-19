# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::Messaging do
  let(:client) { new_client }

  it "GETs history with filters" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/messages")
      .with(query: { number: "2015551234", start: 1, end: 2, type: "sms" })
      .to_return(status: 200, body: envelope(messages: []))
    client.messaging.history(number: "2015551234", start: 1, end_at: 2, type: "sms")
  end

  it "POSTs send_message with camelCased fromNumber / toNumber" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/messages")
      .with(body: { fromNumber: "2012548000", toNumber: "2015551234", text: "hi" }.to_json)
      .to_return(status: 200, body: envelope(id: "abc", type: "sms"))
    expect(client.messaging.send_message(from_number: "2012548000", to_number: "2015551234", text: "hi"))
      .to include("id" => "abc")
  end

  it "POSTs create_brand" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/messaging/brands")
      .with(body: { messagingBrandId: "B1", messagingBrandName: "Acme" }.to_json)
      .to_return(status: 200, body: envelope(result: { status: "Success" }))
    client.messaging.create_brand(messaging_brand_id: "B1", messaging_brand_name: "Acme")
  end

  it "GETs campaign_status" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/messaging/campaigns")
      .to_return(status: 200, body: envelope(campaigns: []))
    client.messaging.campaign_status
  end

  it "POSTs create_campaign" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/messaging/campaigns")
      .to_return(status: 200, body: envelope(result: { status: "Success" }))
    client.messaging.create_campaign(messaging_brand_id: "B1", external_campaign_id: "C1", campaign_description: "x")
  end

  it "GETs numbers_state with no numbers (omits the query param)" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers/messaging")
      .to_return(status: 200, body: envelope(numbers: []))
    client.messaging.numbers_state
  end

  it "GETs numbers_state with a list, joined by comma" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers/messaging")
      .with(query: { numbers: "2015551234,2015551235" })
      .to_return(status: 200, body: envelope(numbers: []))
    client.messaging.numbers_state(numbers: %w[2015551234 2015551235])
  end

  it "raises on 429 (rate-limited)" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/messages")
      .to_return(status: 429, body: { message: "rate limit" }.to_json)
    expect { client.messaging.send_message(from_number: "1", to_number: "2", text: "x") }
      .to raise_error(VoiceTel::ApiError) { |e| expect(e.rate_limit?).to be(true) }
  end
end
