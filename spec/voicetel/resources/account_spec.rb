# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::Account do
  let(:client) { new_client }

  it "GETs the account profile" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account").to_return(
      status: 200,
      body: envelope(username: "u", cash: 4.20,
                     services: { e911: true, cnam: true, intl: false, sms: true },
                     rates: { did: 0.5, sms: 0.005 })
    )
    result = client.account.get
    expect(result).to be_a(VoiceTel::Models::AccountData)
    expect(result.username).to eq("u")
    expect(result.cash).to eq(4.20)
    expect(result.services).to be_a(VoiceTel::Models::AccountServices)
    expect(result.services.e911).to be(true)
    expect(result.rates).to be_a(VoiceTel::Models::AccountRates)
    expect(result.rates.did).to eq(0.5)
  end

  it "no longer exposes services.rcid (removed in API 2.2.11)" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account").to_return(
      status: 200,
      body: envelope(username: "u", services: { e911: true, cnam: true })
    )
    result = client.account.get
    expect(result.services).not_to respond_to(:rcid)
    expect(VoiceTel::Models::AccountServices.members).not_to include(:rcid)
  end

  it "PUTs partial account updates" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/account")
      .with(body: { notify: true, notifyThreshold: 5 }.to_json)
      .to_return(status: 200, body: envelope(updated: %w[notify notifyThreshold]))
    result = client.account.update(notify: true, notify_threshold: 5)
    expect(result).to be_a(VoiceTel::Models::AccountPutData)
    expect(result.updated).to eq(%w[notify notifyThreshold])
  end

  it "POSTs to create a sub-account" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/account")
      .with(body: { username: 1, name: "A", email: "a@b" }.to_json)
      .to_return(status: 200, body: envelope(username: "1"))
    expect(client.account.add(username: 1, name: "A", email: "a@b").username).to eq("1")
  end

  it "POSTs the public signup flow" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/accounts")
      .to_return(status: 200, body: envelope(username: "u"))
    expect(client.account.signup(name: "A", email: "a@b").username).to eq("u")
  end

  it "passes start/end to GET /cdr as query params" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account/cdr?start=1&end=2")
      .to_return(status: 200, body: envelope(cdr: [], start: 1, end: 2))
    result = client.account.cdr(start: 1, end_at: 2)
    expect(result).to be_a(VoiceTel::Models::AccountCdrData)
    expect(result.end_at).to eq(2)
  end

  it "builds CDR rows with their per-call value summaries" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account/cdr")
      .to_return(
        status: 200,
        body: envelope(cdr: [{ id: "c1", key: %w[1000000001 1769000000],
                               value: { dur: "60", dst: "2015550123", ba: "0.05" } }],
                       start: 0, end: 1)
      )
    row = client.account.cdr.cdr.first
    expect(row).to be_a(VoiceTel::Models::CdrEntry)
    expect(row.value).to be_a(VoiceTel::Models::CdrEntryValue)
    expect(row.value.ba).to eq("0.05")
  end

  it "omits cdr query params when nil" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account/cdr")
      .to_return(status: 200, body: envelope(cdr: [], start: 0, end: 0))
    client.account.cdr
  end

  it "GETs credits" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account/credits")
      .to_return(status: 200, body: envelope(credits: []))
    expect(client.account.credits).to be_a(VoiceTel::Models::AccountCreditsData)
  end

  it "GETs recurring_charges" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account/recurring-charges")
      .to_return(status: 200, body: envelope(charges: [], total: 0))
    expect(client.account.recurring_charges).to be_a(VoiceTel::Models::AccountMrcData)
  end

  it "GETs payments" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account/payments")
      .to_return(status: 200, body: envelope(payments: []))
    expect(client.account.payments).to be_a(VoiceTel::Models::AccountPaymentsData)
  end

  it "GETs registration" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account/registration")
      .to_return(status: 200, body: envelope(agent: "sipua"))
    expect(client.account.registration.agent).to eq("sipua")
  end

  it "POSTs recovery without bearer auth" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/account/recovery")
      .with(body: { email: "x@y" }.to_json) { |req| !req.headers.key?("Authorization") }
      .to_return(status: 200, body: envelope(message: "queued"))
    expect(client.account.recover(email: "x@y").message).to eq("queued")
  end

  it "raises an ApiError on 401" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account")
      .to_return(status: 401, body: { message: "expired" }.to_json)
    expect { client.account.get }.to raise_error(VoiceTel::ApiError) { |e| expect(e.authentication?).to be(true) }
  end
end
