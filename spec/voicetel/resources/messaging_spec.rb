# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::Messaging do
  let(:client) { new_client }

  it "GETs history with filters" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/messages")
      .with(query: { number: "2015550123", start: 1, end: 2, type: "sms" })
      .to_return(
        status: 200,
        body: envelope(number: "2015550123", type: "sms", fromTs: 1, toTs: 2,
                       messages: [{ id: "abc", key: ["2015550123", 1_769_000_000],
                                    value: { sourceNumber: "2015550100", direction: "out", rate: "0.005" } }])
      )
    result = client.messaging.history(number: "2015550123", start: 1, end_at: 2, type: "sms")
    expect(result).to be_a(VoiceTel::Models::MessageHistoryData)
    expect(result.messages.first.value.direction).to eq("out")
  end

  it "POSTs send_message with camelCased fromNumber / toNumber" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/messages")
      .with(body: { fromNumber: "2015550100", toNumber: "2015550123", text: "hi" }.to_json)
      .to_return(status: 200, body: envelope(id: "abc", type: "sms", fromNumber: "2015550100",
                                             toNumber: "2015550123", parts: 1))
    result = client.messaging.send_message(from_number: "2015550100", to_number: "2015550123", text: "hi")
    expect(result).to be_a(VoiceTel::Models::MessageSendData)
    expect(result.id).to eq("abc")
    expect(result.parts).to eq(1)
  end

  it "POSTs create_brand" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/messaging/brands")
      .with(body: { messagingBrandId: "B1", messagingBrandName: "Acme" }.to_json)
      .to_return(status: 200, body: envelope(result: { statusCode: "200", status: "Success" }))
    result = client.messaging.create_brand(messaging_brand_id: "B1", messaging_brand_name: "Acme")
    expect(result.result.status).to eq("Success")
  end

  def stub_campaign_status_with_dca
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/messaging/campaigns").to_return(
      status: 200,
      body: envelope(
        campaigns: [
          {
            id: "CAMP002",
            status: "CAMPAIGN_PENDING_DCA",
            numbers: ["2015550123"],
            dca: {
              electionComplete: false,
              electedCarriers: ["AT&T", "T-Mobile"],
              carriers: [
                { carrier: "T-Mobile", status: "ACTIVE", detail: "Campaign approved",
                  updatedAt: "2026-10-13T10:00:00Z" }
              ]
            }
          }
        ]
      )
    )
  end

  it "GETs campaign_status with carrier (DCA) review progress" do
    stub_campaign_status_with_dca
    result = client.messaging.campaign_status
    expect(result).to be_a(VoiceTel::Models::MessagingCampaignStatusData)
    item = result.campaigns.first
    expect(item).to be_a(VoiceTel::Models::CampaignStatusItem)
    expect(item.status).to eq("CAMPAIGN_PENDING_DCA")
    expect(item.numbers).to eq(["2015550123"])
    expect(item.dca).to be_a(VoiceTel::Models::CampaignDca)
    expect(item.dca.election_complete).to be(false)
    expect(item.dca.elected_carriers).to eq(["AT&T", "T-Mobile"])
  end

  it "decodes per-carrier DCA decisions" do
    stub_campaign_status_with_dca
    decision = client.messaging.campaign_status.campaigns.first.dca.carriers.first
    expect(decision).to be_a(VoiceTel::Models::CampaignDcaCarrier)
    expect(decision.carrier).to eq("T-Mobile")
    expect(decision.status).to eq("ACTIVE")
    expect(decision.detail).to eq("Campaign approved")
  end

  it "GETs campaign_status with a completed DCA review and null electedCarriers" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/messaging/campaigns").to_return(
      status: 200,
      body: envelope(
        campaigns: [
          {
            id: "CAMP002",
            status: "CAMPAIGN_DCA_COMPLETE",
            numbers: %w[2015550123 2015551235],
            dca: { electionComplete: true, electedCarriers: nil, carriers: [] }
          }
        ]
      )
    )
    item = client.messaging.campaign_status.campaigns.first
    expect(item.status).to eq("CAMPAIGN_DCA_COMPLETE")
    expect(item.dca.election_complete).to be(true)
    expect(item.dca.elected_carriers).to be_nil
  end

  it "GETs campaign_status where dca is null for CAMPAIGN_INVALID_ID" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/messaging/campaigns").to_return(
      status: 200,
      body: envelope(campaigns: [{ id: "CNOPE", status: "CAMPAIGN_INVALID_ID", numbers: [], dca: nil }])
    )
    item = client.messaging.campaign_status.campaigns.first
    expect(item.status).to eq("CAMPAIGN_INVALID_ID")
    expect(item.dca).to be_nil
  end

  it "POSTs create_campaign" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/messaging/campaigns")
      .with(body: { messagingBrandId: "B1", externalCampaignId: "C1", campaignDescription: "x" }.to_json)
      .to_return(status: 200, body: envelope(result: { statusCode: "200", status: "Success" }))
    result = client.messaging.create_campaign(messaging_brand_id: "B1", external_campaign_id: "C1", campaign_description: "x")
    expect(result.result.status_code).to eq("200")
  end

  it "GETs numbers_state with no numbers (omits the query param)" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers/messaging")
      .to_return(status: 200, body: envelope(numbers: []))
    expect(client.messaging.numbers_state).to be_a(VoiceTel::Models::NumbersMessagingListData)
  end

  it "GETs numbers_state with a list, joined by comma" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers/messaging")
      .with(query: { numbers: "2015550123,2015551235" })
      .to_return(status: 200, body: envelope(numbers: []))
    client.messaging.numbers_state(numbers: %w[2015550123 2015551235])
  end

  it "raises on 429 (rate-limited)" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/messages")
      .to_return(status: 429, body: { message: "rate limit" }.to_json)
    expect { client.messaging.send_message(from_number: "1", to_number: "2", text: "x") }
      .to raise_error(VoiceTel::ApiError) { |e| expect(e.rate_limit?).to be(true) }
  end
end
