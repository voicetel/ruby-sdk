# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Models
    # Request bodies take a 10-digit TN in `dn`; responses return the
    # 11-digit E.164 US form (leading 1). This mirrors the spec exactly.

    # ------------------------------------------------------------- requests ---
    # Body for POST /v2.2/e911/validations — validate an address.
    E911AddressRequest = Data.define(:address1, :address2, :city, :state, :zip) do
      include Request
    end

    # Body for POST /v2.2/e911 — validate and provision in one call.
    E911CreateRequest = Data.define(
      :dn, :callername, :address1, :address2, :city, :state, :zip
    ) do
      include Request
    end

    # Body for PUT /v2.2/e911/{dn} — provision using a previously-validated
    # addressid from POST /v2.2/e911/validations.
    E911ProvisionByIdRequest = Data.define(:callername, :addressid) do
      include Request
    end

    # ---------------------------------------------------- entities & data ---
    # An e911 record bound to a TN. Returned by GET/POST/PUT /v2.2/e911(/{dn}).
    E911Entry = Data.define(
      :dn, :callername, :address1, :address2, :city, :state, :zip
    ) do
      extend Base
    end

    # Validation result from POST /v2.2/e911/validations. addressid is
    # passed to E911ProvisionByIdRequest to provision the address.
    E911ValidatedAddress = Data.define(
      :addressid, :address1, :address2, :city, :state, :zip
    ) do
      extend Base
    end

    # Data payload from GET /v2.2/e911.
    E911AllData = Data.define(:records) do
      extend Base

      def self.nested
        { records: E911Entry }
      end
    end

    # Data payload from GET/POST/PUT /v2.2/e911/{dn}.
    E911RecordData = Data.define(:record) do
      extend Base

      def self.nested
        { record: E911Entry }
      end
    end

    # Data payload from POST /v2.2/e911/validations.
    E911ValidateData = Data.define(:address) do
      extend Base

      def self.nested
        { address: E911ValidatedAddress }
      end
    end
  end
end
