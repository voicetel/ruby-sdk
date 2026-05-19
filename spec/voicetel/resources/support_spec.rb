# frozen_string_literal: true

RSpec.describe VoiceTel::Resources::Support do
  let(:client) { new_client }

  it "lists tickets" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/support/tickets").to_return(status: 200, body: envelope(tickets: []))
    client.support.list
  end

  it "creates a ticket" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/support/tickets")
      .with(body: { subject: "x", message: "y" }.to_json)
      .to_return(status: 200, body: envelope(ticket: { id: 1, number: 1015 }))
    result = client.support.create(subject: "x", message: "y")
    # number is the ticket sequence, not a phone number — but on the wire it is "number".
    expect(result["ticket"]).to include("id" => 1, "number" => 1015)
  end

  it "gets a ticket" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/support/tickets/42")
      .to_return(status: 200, body: envelope(ticket: { id: 42, number: 1015, subject: "x" }))
    expect(client.support.get(42)["ticket"]["number"]).to eq(1015)
  end

  it "updates a ticket" do
    stub_request(:put, "#{SpecHelpers::BASE_URL}/v2.2/support/tickets/42")
      .with(body: { status: "closed" }.to_json)
      .to_return(status: 200, body: envelope(status: "success"))
    client.support.update(42, status: "closed")
  end

  it "deletes a ticket (204)" do
    stub_request(:delete, "#{SpecHelpers::BASE_URL}/v2.2/support/tickets/42").to_return(status: 204, body: "")
    expect(client.support.delete(42)).to be_nil
  end

  it "lists messages" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/support/tickets/42/messages")
      .to_return(status: 200, body: envelope(messages: []))
    client.support.messages(42)
  end

  it "replies" do
    stub_request(:post, "#{SpecHelpers::BASE_URL}/v2.2/support/tickets/42/replies")
      .with(body: { message: "thanks" }.to_json)
      .to_return(status: 200, body: envelope(message: "Reply added"))
    expect(client.support.reply(42, message: "thanks")).to eq("message" => "Reply added")
  end

  it "raises on 404" do
    stub_request(:get, "#{SpecHelpers::BASE_URL}/v2.2/support/tickets/9999")
      .to_return(status: 404, body: { message: "not found" }.to_json)
    expect { client.support.get(9999) }.to raise_error(VoiceTel::ApiError) { |e| expect(e.not_found?).to be(true) }
  end
end
