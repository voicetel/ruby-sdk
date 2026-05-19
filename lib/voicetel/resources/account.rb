# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # AccountService — Account tag in the OpenAPI spec.
    #
    # Rate-limited endpoints (6 req/hour/IP, shared with Client#login):
    # `cdr`, `recurring_charges`, `payments`, `registration`, and `info`.
    class Account < Base
      # GET /v2.2/account — return the authenticated account profile.
      def get
        @transport.request(:get, "/v2.2/account")
      end

      # PUT /v2.2/account — partial-update account settings.
      def update(body)
        @transport.request(:put, "/v2.2/account", body: body)
      end

      # POST /v2.2/account — create a sub-account (admin-only).
      def add(body)
        @transport.request(:post, "/v2.2/account", body: body)
      end

      # POST /v2.2/accounts — public sign-up flow.
      def signup(body)
        @transport.request(:post, "/v2.2/accounts", body: body)
      end

      # GET /v2.2/account/cdr — call detail records. Rate-limited.
      def cdr(start: nil, end_at: nil)
        q = compact_query("start" => start, "end" => end_at)
        @transport.request(:get, "/v2.2/account/cdr", query: q)
      end

      # GET /v2.2/account/credits — credit history.
      def credits
        @transport.request(:get, "/v2.2/account/credits")
      end

      # GET /v2.2/account/recurring-charges — active monthly recurring charges. Rate-limited.
      def recurring_charges
        @transport.request(:get, "/v2.2/account/recurring-charges")
      end

      # GET /v2.2/account/payments — payment history. Rate-limited.
      def payments
        @transport.request(:get, "/v2.2/account/payments")
      end

      # GET /v2.2/account/registration — current SIP registration. Rate-limited.
      def registration
        @transport.request(:get, "/v2.2/account/registration")
      end

      # POST /v2.2/account/recovery — start password recovery. No auth required.
      def recover(body)
        @transport.request(:post, "/v2.2/account/recovery", body: body, require_auth: false)
      end
    end
  end
end
