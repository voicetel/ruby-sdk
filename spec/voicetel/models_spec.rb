# frozen_string_literal: true

RSpec.describe VoiceTel::Models do
  describe ".wire_key" do
    it "camelCases member names" do
      expect(described_class.wire_key(:campaign_id)).to eq("campaignId")
      expect(described_class.wire_key(:upstream_cnp_id)).to eq("upstreamCnpId")
      expect(described_class.wire_key(:sms_enabled)).to eq("smsEnabled")
      expect(described_class.wire_key(:e911)).to eq("e911")
      expect(described_class.wire_key(:state)).to eq("state")
    end
  end

  describe ".build" do
    it "maps camelCase wire keys onto snake_case members" do
      job = described_class::MessagingEnablementJob.build(
        { "campaignId" => "CAMP002", "state" => "done", "message" => "enabled",
          "createdAt" => "2026-10-13T10:00:00Z", "updatedAt" => "2026-10-13T10:05:00Z" }
      )
      expect(job.campaign_id).to eq("CAMP002")
      expect(job.state).to eq("done")
      expect(job.created_at).to eq("2026-10-13T10:00:00Z")
    end

    it "ignores unknown wire keys so the server can add fields" do
      job = described_class::MessagingEnablementJob.build(
        { "campaignId" => "CAMP002", "state" => "done", "message" => "ok",
          "createdAt" => "t", "updatedAt" => "t", "brandNewField" => "surprise" }
      )
      expect(job.state).to eq("done")
    end

    it "defaults members missing from the payload to nil" do
      job = described_class::MessagingEnablementJob.build({ "campaignId" => "CAMP002" })
      expect(job.state).to be_nil
      expect(job.message).to be_nil
    end

    it "builds nil to nil and passes non-Hash payloads through" do
      expect(described_class::MessagingEnablementJob.build(nil)).to be_nil
      expect(described_class::MessagingEnablementJob.build("plain")).to eq("plain")
    end

    it "builds declared members from either an object or a list" do
      single = described_class::CampaignStatusItem.build(
        { "id" => "C1", "status" => "CAMPAIGN_PENDING_DCA", "numbers" => [],
          "dca" => { "electionComplete" => true, "carriers" => [] } }
      )
      expect(single.dca).to be_a(described_class::CampaignDca)

      list = described_class::MessagingCampaignStatusData.build(
        { "campaigns" => [{ "id" => "C1", "status" => "CAMPAIGN_PENDING_DCA", "numbers" => [] },
                          { "id" => "C2", "status" => "CAMPAIGN_INVALID_ID", "numbers" => [] }] }
      )
      expect(list.campaigns).to all(be_a(described_class::CampaignStatusItem))
    end

    it "honors wire-key aliases" do
      conversation = described_class::SupportConversation.build({ "id" => 1, "number" => 1015, "status" => "active" })
      expect(conversation.ticket_number).to eq(1015)
    end

    it "keeps undeclared list members as plain values" do
      dca = described_class::CampaignDca.build(
        { "electionComplete" => false, "electedCarriers" => ["AT&T", "Verizon Wireless"], "carriers" => [] }
      )
      expect(dca.elected_carriers).to eq(["AT&T", "Verizon Wireless"])
    end
  end

  describe "#to_payload" do
    it "renders a snake_case Hash and drops nil members" do
      request = described_class::NumberMessagingPatchRequest.new(route_in: 1, route_out: nil)
      expect(request.to_payload).to eq({ route_in: 1 })
    end

    it "renders nested request models and hashes inside arrays" do
      request = described_class::OrderCreateRequest.new(
        numbers: [
          "2015550123",
          described_class::OrderNumberSpec.new(number: "2015551235", route: 4),
          { number: "2015551236", route: 8 }
        ]
      )
      expect(request.to_payload).to eq(
        { numbers: ["2015550123", { number: "2015551235", route: 4 }, { number: "2015551236", route: 8 }] }
      )
    end
  end
end
