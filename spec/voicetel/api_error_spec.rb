# frozen_string_literal: true

RSpec.describe VoiceTel::ApiError do
  describe ".kind_from_status" do
    it "maps HTTP status codes to symbols" do
      {
        400 => :bad_request,
        401 => :authentication,
        403 => :permission_denied,
        404 => :not_found,
        409 => :conflict,
        429 => :rate_limit,
        500 => :server,
        502 => :server,
        599 => :server,
        418 => :unknown,
        200 => :unknown
      }.each do |code, kind|
        expect(described_class.kind_from_status(code)).to eq(kind)
      end
    end
  end

  describe ".from_response" do
    it "constructs an ApiError with kind, status, code, message, and body" do
      err = described_class.from_response(404, "ENOENT", "not here", { hint: "use a real id" })
      expect(err).to be_a(described_class)
      expect(err.kind).to eq(:not_found)
      expect(err.status_code).to eq(404)
      expect(err.code).to eq("ENOENT")
      expect(err.message).to eq("not here")
      expect(err.body).to eq(hint: "use a real id")
    end
  end

  describe "convenience predicates" do
    it "returns true for the matching kind and false otherwise" do
      err = described_class.new("boom", kind: :rate_limit, status_code: 429)
      expect(err.rate_limit?).to be(true)
      expect(err.not_found?).to be(false)
      expect(err.conflict?).to be(false)
      expect(err.authentication?).to be(false)
    end

    it "defines a predicate for every kind" do
      described_class::KINDS.each do |k|
        err = described_class.new("x", kind: k)
        expect(err.public_send("#{k}?")).to be(true)
      end
    end
  end
end
