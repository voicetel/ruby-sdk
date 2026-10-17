# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Models
    # --------------------------------------------------------- shared subtypes ---
    # Per-service rates on an account. Read-only for non-administrators.
    AccountRates = Data.define(
      :cnam, :intl_max, :nibble, :lrn, :fax, :tf_adj, :did, :mms, :sms
    ) do
      extend Base
    end

    # Per-service feature flags on an account; true = enabled.
    AccountServices = Data.define(
      :e911, :cnam, :bypass_media, :intl, :mms, :dialer, :sms
    ) do
      extend Base
    end

    # A single credit row in AccountCreditsData.
    CreditEntry = Data.define(:date, :paid, :amount) do
      extend Base
    end

    # A single payment row in AccountPaymentsData. status is one of
    # "Completed", "Pending", "Reversed", "Refunded", "Failed", "Denied",
    # or "Canceled_Reversal".
    PaymentEntry = Data.define(:transaction_id, :date, :payer_email, :status, :amount) do
      extend Base
    end

    # Per-call billing summary inside a CdrEntry. The numeric-looking fields
    # (dur, ba, nr) are intentionally strings to preserve exact precision on
    # the wire.
    CdrEntryValue = Data.define(:dur, :dst, :ba, :nr, :cn, :ip, :cid) do
      extend Base
    end

    # A single CDR row. key is [accountUsername, startEpochUnixSeconds].
    CdrEntry = Data.define(:id, :key, :value) do
      extend Base

      def self.nested
        { value: CdrEntryValue }
      end
    end

    # A single monthly-recurring charge row in AccountMrcData.
    MrcCharge = Data.define(:amount, :description) do
      extend Base
    end

    # ------------------------------------------------------------- requests ---
    # Body for POST /v2.2/account — admin-only sub-account creation.
    AccountAddRequest = Data.define(:username, :name, :email, :master_account) do
      include Request
    end

    # Body for PUT /v2.2/account — partial account-settings update.
    AccountPutRequest = Data.define(
      :notify, :notify_threshold, :timezone, :caller_id, :e911, :intl, :sms, :mms, :ccs
    ) do
      include Request
    end

    # Body for POST /v2.2/accounts — public sign-up.
    AccountSignupRequest = Data.define(:name, :email, :promo) do
      include Request
    end

    # Body for POST /v2.2/account/recovery — password recovery (no auth).
    AccountRecoverRequest = Data.define(:email) do
      include Request
    end

    # Body for POST /v2.2/account/api-key — username/password -> bearer.
    ApiKeyRequest = Data.define(:username, :password) do
      include Request
    end

    # ------------------------------------------------------ response data ---
    # Data payload from POST /v2.2/account (admin create).
    AccountAddData = Data.define(:password, :email, :master_account, :username, :name) do
      extend Base
    end

    # Data payload from POST /v2.2/account/api-key.
    AccountApiKeyData = Data.define(:apikey) do
      extend Base
    end

    # Data payload from GET /v2.2/account/cdr.
    AccountCdrData = Data.define(:cdr, :start, :end_at) do
      extend Base

      def self.nested
        { cdr: CdrEntry }
      end

      def self.wire_keys
        { end_at: "end" }
      end
    end

    # Data payload from GET /v2.2/account/credits.
    AccountCreditsData = Data.define(:credits) do
      extend Base

      def self.nested
        { credits: CreditEntry }
      end
    end

    # Data payload from GET /v2.2/account — the authenticated account's
    # profile.
    AccountData = Data.define(
      :username, :name, :email, :enabled, :created, :cash, :caller_id, :timezone,
      :auth_type, :ccs, :notify, :notify_threshold, :rates, :services
    ) do
      extend Base

      def self.nested
        { rates: AccountRates, services: AccountServices }
      end
    end

    # Data payload from GET /v2.2/account/recurring-charges.
    AccountMrcData = Data.define(:charges, :total) do
      extend Base

      def self.nested
        { charges: MrcCharge }
      end
    end

    # Data payload from GET /v2.2/account/payments.
    AccountPaymentsData = Data.define(:payments) do
      extend Base

      def self.nested
        { payments: PaymentEntry }
      end
    end

    # Data payload from PUT /v2.2/account.
    AccountPutData = Data.define(:updated) do
      extend Base
    end

    # Data payload from POST /v2.2/account/recovery.
    AccountRecoverData = Data.define(:message) do
      extend Base
    end

    # Data payload from GET /v2.2/account/registration — current SIP
    # registration.
    AccountRegistrationData = Data.define(:agent, :uri) do
      extend Base
    end

    # Data payload from POST /v2.2/accounts (public sign-up).
    AccountSignupData = Data.define(:username, :name, :email, :password) do
      extend Base
    end
  end
end
