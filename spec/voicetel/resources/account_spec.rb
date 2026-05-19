# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::Account do
  let(:client) { new_client }

  it "GETs the account profile" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account")
      .to_return(status: 200, body: envelope(username: "u", cash: 4.20))
    expect(client.account.get).to eq("username" => "u", "cash" => 4.20)
  end

  it "PUTs partial account updates" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/account")
      .with(body: { notify: true, notifyThreshold: 5 }.to_json)
      .to_return(status: 200, body: envelope(updated: %w[notify notifyThreshold]))
    expect(client.account.update(notify: true, notify_threshold: 5)).to eq("updated" => %w[notify notifyThreshold])
  end

  it "POSTs to create a sub-account" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/account")
      .with(body: { username: 1, name: "A", email: "a@b" }.to_json)
      .to_return(status: 200, body: envelope(username: "1"))
    expect(client.account.add(username: 1, name: "A", email: "a@b")).to eq("username" => "1")
  end

  it "POSTs the public signup flow" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/accounts")
      .to_return(status: 200, body: envelope(username: "u"))
    expect(client.account.signup(name: "A", email: "a@b")).to eq("username" => "u")
  end

  it "passes start/end to GET /cdr as query params" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account/cdr?start=1&end=2")
      .to_return(status: 200, body: envelope(cdr: []))
    client.account.cdr(start: 1, end_at: 2)
  end

  it "omits cdr query params when nil" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account/cdr")
      .to_return(status: 200, body: envelope(cdr: []))
    client.account.cdr
  end

  it "GETs credits" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account/credits")
      .to_return(status: 200, body: envelope(credits: []))
    client.account.credits
  end

  it "GETs recurring_charges" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account/recurring-charges")
      .to_return(status: 200, body: envelope(charges: [], total: 0))
    client.account.recurring_charges
  end

  it "GETs payments" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account/payments")
      .to_return(status: 200, body: envelope(payments: []))
    client.account.payments
  end

  it "GETs registration" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account/registration")
      .to_return(status: 200, body: envelope(agent: "sipua"))
    client.account.registration
  end

  it "POSTs recovery without bearer auth" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/account/recovery")
      .with(body: { email: "x@y" }.to_json) { |req| !req.headers.key?("Authorization") }
      .to_return(status: 200, body: envelope(message: "queued"))
    expect(client.account.recover(email: "x@y")).to eq("message" => "queued")
  end

  it "raises an ApiError on 401" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/account")
      .to_return(status: 401, body: { message: "expired" }.to_json)
    expect { client.account.get }.to raise_error(VoiceTel::ApiError) { |e| expect(e.authentication?).to be(true) }
  end
end
