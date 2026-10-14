# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # AccountService — Account tag in the OpenAPI spec.
    #
    # Rate-limited endpoints (6 req/hour/IP, shared with Client#login):
    # `cdr`, `recurring_charges`, `payments`, `registration`, and `info`.
    class Account < Base
      # GET /v2.2/account — the authenticated account profile.
      #
      # @return [Models::AccountData]
      def get
        Models::AccountData.build(@transport.request(:get, "/v2.2/account"))
      end

      # PUT /v2.2/account — partial-update account settings.
      #
      # @return [Models::AccountPutData]
      def update(body)
        Models::AccountPutData.build(@transport.request(:put, "/v2.2/account", body: payload(body)))
      end

      # POST /v2.2/account — create a sub-account (admin-only).
      #
      # @return [Models::AccountAddData]
      def add(body)
        Models::AccountAddData.build(@transport.request(:post, "/v2.2/account", body: payload(body)))
      end

      # POST /v2.2/accounts — public sign-up flow.
      #
      # @return [Models::AccountSignupData]
      def signup(body)
        Models::AccountSignupData.build(@transport.request(:post, "/v2.2/accounts", body: payload(body)))
      end

      # GET /v2.2/account/cdr — call detail records. Rate-limited.
      #
      # @return [Models::AccountCdrData]
      def cdr(start: nil, end_at: nil)
        q = compact_query("start" => start, "end" => end_at)
        Models::AccountCdrData.build(@transport.request(:get, "/v2.2/account/cdr", query: q))
      end

      # GET /v2.2/account/credits — credit history.
      #
      # @return [Models::AccountCreditsData]
      def credits
        Models::AccountCreditsData.build(@transport.request(:get, "/v2.2/account/credits"))
      end

      # GET /v2.2/account/recurring-charges — active monthly recurring
      # charges. Rate-limited.
      #
      # @return [Models::AccountMrcData]
      def recurring_charges
        Models::AccountMrcData.build(@transport.request(:get, "/v2.2/account/recurring-charges"))
      end

      # GET /v2.2/account/payments — payment history. Rate-limited.
      #
      # @return [Models::AccountPaymentsData]
      def payments
        Models::AccountPaymentsData.build(@transport.request(:get, "/v2.2/account/payments"))
      end

      # GET /v2.2/account/registration — current SIP registration. Rate-limited.
      #
      # @return [Models::AccountRegistrationData]
      def registration
        Models::AccountRegistrationData.build(@transport.request(:get, "/v2.2/account/registration"))
      end

      # POST /v2.2/account/recovery — start password recovery. No auth required.
      #
      # @return [Models::AccountRecoverData]
      def recover(body)
        Models::AccountRecoverData.build(
          @transport.request(:post, "/v2.2/account/recovery", body: payload(body), require_auth: false)
        )
      end
    end
  end
end
