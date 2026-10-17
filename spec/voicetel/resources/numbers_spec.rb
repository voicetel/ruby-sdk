# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::Numbers do
  let(:client) { new_client }

  it "lists all numbers" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers").to_return(
      status: 200,
      body: envelope(numbers: [{ number: "2015550123", translated: "2015550123", route: 4, cnam: true,
                                 forward: false, carrier: 1, smsEnabled: true, faxEnabled: false }])
    )
    result = client.numbers.list
    expect(result).to be_a(VoiceTel::Models::NumbersListData)
    expect(result.numbers.first).to be_a(VoiceTel::Models::NumberDetail)
    expect(result.numbers.first.number).to eq("2015550123")
    expect(result.numbers.first.sms_enabled).to be(true)
  end

  it "adds a number" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/numbers")
      .with(body: { number: "2015550123", route: 4 }.to_json)
      .to_return(status: 200, body: envelope(number: "2015550123", route: 4))
    result = client.numbers.add(number: "2015550123", route: 4)
    expect(result).to be_a(VoiceTel::Models::NumberAddData)
    expect(result.route).to eq(4)
  end

  it "accepts a request model in place of a Hash body" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/numbers")
      .with(body: { number: "2015550123", route: 4 }.to_json)
      .to_return(status: 200, body: envelope(number: "2015550123", route: 4))
    client.numbers.add(VoiceTel::Models::NumberAddRequest.new(number: "2015550123", route: 4))
  end

  it "GETs one number" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123").to_return(status: 200, body: envelope(number: "2015550123"))
    expect(client.numbers.get("2015550123")).to be_a(VoiceTel::Models::NumberDetail)
  end

  it "removes a number (204)" do
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123").to_return(status: 204, body: "")
    expect(client.numbers.remove("2015550123")).to be_nil
  end

  it "moves a number (PATCH)" do
    stub_request(:patch, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123")
      .with(body: { accountId: 2, route: 4 }.to_json)
      .to_return(status: 200, body: envelope(number: "2015550123", accountId: 2, route: 4))
    result = client.numbers.move("2015550123", account_id: 2, route: 4)
    expect(result).to be_a(VoiceTel::Models::NumberMoveData)
    expect(result.account_id).to eq(2)
  end

  it "releases a number" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/release").to_return(status: 204, body: "")
    expect(client.numbers.release("2015550123")).to be_nil
  end

  it "sets route" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/route")
      .with(body: { route: 5 }.to_json).to_return(status: 200, body: envelope(number: "2015550123", route: 5))
    expect(client.numbers.set_route("2015550123", route: 5).route).to eq(5)
  end

  it "sets translation" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/translation")
      .with(body: { translation: "100" }.to_json).to_return(status: 200, body: envelope(number: "2015550123", translation: "100"))
    expect(client.numbers.set_translation("2015550123", translation: "100").translation).to eq("100")
  end

  it "sets cnam" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/cnam")
      .with(body: { enabled: true }.to_json).to_return(status: 200, body: envelope(number: "2015550123", cnam: true))
    expect(client.numbers.set_cnam("2015550123", enabled: true).cnam).to be(true)
  end

  it "sets lidb" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/lidb")
      .with(body: { cnam: "ACME" }.to_json)
      .to_return(status: 200, body: envelope(number: "2015550123", cnam: "ACME", carrierStatus: "Success"))
    expect(client.numbers.set_lidb("2015550123", cnam: "ACME").cnam).to eq("ACME")
  end

  it "gets/sets/removes fax" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/fax").to_return(status: 200,
                                                                                         body: envelope(
                                                                                           number: "2015550123", email: "a@b"
                                                                                         ))
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/fax").to_return(status: 200,
                                                                                         body: envelope(
                                                                                           number: "2015550123", email: "a@b"
                                                                                         ))
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/fax").to_return(status: 204, body: "")
    expect(client.numbers.get_fax("2015550123").email).to eq("a@b")
    client.numbers.set_fax("2015550123", email: "a@b")
    expect(client.numbers.remove_fax("2015550123")).to be_nil
  end

  it "sets/removes forward" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/forward")
      .to_return(status: 200, body: envelope(number: "2015550123", forwardTo: "2"))
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/forward").to_return(status: 204, body: "")
    expect(client.numbers.set_forward("2015550123", destination: 2_125_551_234).forward_to).to eq("2")
    expect(client.numbers.remove_forward("2015550123")).to be_nil
  end

  it "gets/sets/removes sms" do
    sms_body = envelope(number: "2015550123", type: "email", resource: "a@b")
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/sms")
      .to_return(status: 200, body: sms_body)
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/sms")
      .to_return(status: 200, body: sms_body)
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/sms").to_return(status: 204, body: "")
    expect(client.numbers.get_sms("2015550123").type).to eq("email")
    client.numbers.set_sms("2015550123", type: "email", resource: "a@b")
    expect(client.numbers.remove_sms("2015550123")).to be_nil
  end

  it "gets messaging state including a path-C pending job" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/messaging").to_return(
      status: 200,
      body: envelope(
        number: "2015550123", onAccount: true, enabled: false, carrier: 1, routeIn: 0,
        resource: "", network: "C", campaign: nil,
        pending: { campaignId: "CAMP002", state: "hosting", message: "hosting numbers",
                   createdAt: "2026-10-13T10:00:00Z", updatedAt: "2026-10-13T10:05:00Z" }
      )
    )
    result = client.numbers.get_messaging("2015550123")
    expect(result).to be_a(VoiceTel::Models::NumberMessagingState)
    expect(result.network).to eq("C")
    expect(result.campaign).to be_nil
    expect(result.pending).to be_a(VoiceTel::Models::MessagingEnablementJob)
    expect(result.pending.campaign_id).to eq("CAMP002")
    expect(result.pending.state).to eq("hosting")
  end

  it "gets messaging state on the legacy path-A network" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/messaging").to_return(
      status: 200,
      body: envelope(
        number: "2015550123", enabled: true, carrier: 19, routeIn: 0, resource: "",
        network: "A",
        campaign: { id: "CABC123", network: "A", status: "ACTIVE", upstreamCnpId: "CAMP004" },
        pending: nil
      )
    )
    result = client.numbers.get_messaging("2015550123")
    expect(result.network).to eq("A")
    expect(result.campaign).to be_a(VoiceTel::Models::CampaignBinding)
    expect(result.campaign.upstream_cnp_id).to eq("CAMP004")
    expect(result.pending).to be_nil
  end

  it "patches messaging state" do
    stub_request(:patch, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/messaging")
      .with(body: { routeIn: 1 }.to_json)
      .to_return(status: 200, body: envelope(number: "2015550123", updated: ["routeIn"]))
    result = client.numbers.patch_messaging("2015550123", route_in: 1)
    expect(result.updated).to eq(["routeIn"])
  end

  it "assigns a campaign synchronously on path B (status enabled)" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/messaging-campaign")
      .with(body: { campaignId: "CAMP002" }.to_json)
      .to_return(
        status: 200,
        body: envelope(
          number: "2015550123", campaignId: "CAMP002", status: "enabled", network: "B",
          upstreamCnpId: "CAMP003", carrier: 19, alreadyAssigned: false, orderId: "98765",
          previousNetwork: "A", previousNetworkCleared: true, warning: nil, message: nil, job: nil
        )
      )
    result = client.numbers.assign_campaign("2015550123", campaign_id: "CAMP002")
    expect(result).to be_a(VoiceTel::Models::NumberMessagingCampaignAssignData)
    expect(result.status).to eq("enabled")
    expect(result.network).to eq("B")
    expect(result.carrier).to eq(19)
    expect(result.already_assigned).to be(false)
    expect(result.order_id).to eq("98765")
    expect(result.previous_network).to eq("A")
    expect(result.job).to be_nil
  end

  it "reports an idempotent campaign assignment as already" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/messaging-campaign")
      .with(body: { campaignId: "CAMP002" }.to_json)
      .to_return(
        status: 200,
        body: envelope(
          number: "2015550123", campaignId: "CAMP002", status: "already", network: "C",
          upstreamCnpId: "BANDW", carrier: 1, alreadyAssigned: true, orderId: nil,
          previousNetwork: nil, previousNetworkCleared: false, warning: nil, message: nil, job: nil
        )
      )
    result = client.numbers.assign_campaign("2015550123", campaign_id: "CAMP002")
    expect(result.status).to eq("already")
    expect(result.already_assigned).to be(true)
    expect(result.order_id).to be_nil
    expect(result.previous_network).to be_nil
  end

  it "reports an async path-C assignment as pending with a job" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/messaging-campaign")
      .with(body: { campaignId: "CAMP002" }.to_json)
      .to_return(
        status: 202,
        body: envelope(
          number: "2015550123", campaignId: "CAMP002", status: "pending", network: "C",
          upstreamCnpId: "BANDW", carrier: 1, alreadyAssigned: false, orderId: nil,
          previousNetwork: "A", previousNetworkCleared: false,
          warning: "stale registration on path B; removal requested",
          message: "accepted; provisioning started",
          job: { campaignId: "CAMP002", state: "queued", message: "queued for hosting",
                 createdAt: "2026-10-13T10:00:00Z", updatedAt: "2026-10-13T10:00:00Z" }
        )
      )
    result = client.numbers.assign_campaign("2015550123", campaign_id: "CAMP002")
    expect(result.status).to eq("pending")
    expect(result.network).to eq("C")
    expect(result.upstream_cnp_id).to eq("BANDW")
    expect(result.message).to eq("accepted; provisioning started")
    expect(result.warning).to include("stale registration")
    expect(result.job).to be_a(VoiceTel::Models::MessagingEnablementJob)
    expect(result.job.state).to eq("queued")
    expect(result.job.message).to eq("queued for hosting")
  end

  it "unassigns a campaign (DELETE returns 200 + body, not 204)" do
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/messaging-campaign")
      .with(query: { campaignId: "CABC123" })
      .to_return(
        status: 200,
        body: envelope(number: "2015550123", campaignId: "CABC123", network: "B",
                       upstreamCnpId: "CAMP003", unassigned: true)
      )
    result = client.numbers.unassign_campaign("2015550123", campaign_id: "CABC123")
    expect(result).to be_a(VoiceTel::Models::NumberMessagingCampaignUnassignData)
    expect(result.unassigned).to be(true)
    expect(result.network).to eq("B")
  end

  it "bulk-unassigns campaigns (DELETE returns 200 + body, query params only)" do
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/numbers/messaging-campaign")
      .with(query: { numbers: "2015550123,2015551235", campaignId: "CABC123" })
      .to_return(
        status: 200,
        body: envelope(campaignId: "CABC123", network: "B", upstreamCnpId: "CAMP003",
                       unassignedNumbers: %w[2015550123 2015551235],
                       failed: [{ number: "2015550199", reason: "not on account" }])
      )
    result = client.numbers.bulk_unassign_campaign(numbers: %w[2015550123 2015551235], campaign_id: "CABC123")
    expect(result).to be_a(VoiceTel::Models::NumbersMessagingCampaignUnassignData)
    expect(result.unassigned_numbers).to eq(%w[2015550123 2015551235])
    expect(result.failed.first).to be_a(VoiceTel::Models::CampaignUnassignFailure)
    expect(result.failed.first.reason).to eq("not on account")
  end

  it "sets port-out PIN and reports changed=true" do
    stub_request(:patch, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/port-out-pin")
      .with(body: { pin: "1234" }.to_json)
      .to_return(status: 200, body: envelope(number: "2015550123", portOutPin: "1234", changed: true))
    result = client.numbers.set_port_out_pin("2015550123", pin: "1234")
    expect(result).to be_a(VoiceTel::Models::PortOutPinUpdateData)
    expect(result.port_out_pin).to eq("1234")
    expect(result.changed).to be(true)
  end

  it "returns an already-locked port-out PIN unchanged with changed=false" do
    stub_request(:patch, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123/port-out-pin")
      .with(body: { pin: "1234" }.to_json)
      .to_return(status: 200, body: envelope(number: "2015550123", portOutPin: "9999", changed: false))
    result = client.numbers.set_port_out_pin("2015550123", pin: "1234")
    expect(result.port_out_pin).to eq("9999")
    expect(result.changed).to be(false)
  end

  it "raises on 403 permission denied" do
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/numbers/2015550123")
      .to_return(status: 403, body: { message: "denied" }.to_json)
    expect { client.numbers.remove("2015550123") }.to raise_error(VoiceTel::ApiError) { |e| expect(e.permission_denied?).to be(true) }
  end
end
