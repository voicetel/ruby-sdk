# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Models
    # Data payload from GET /v2.2/cnam/{number}.
    CnamData = Data.define(:cnam, :number) do
      extend Base
    end

    # LRN dip result. Returned nested inside LrnLookupData for the full
    # /v2.2/lrn/{n}/{ani} form.
    LrnData = Data.define(
      :lrn, :state, :city, :rc, :lata, :ocn, :lec, :lec_type, :jurisdiction, :local
    ) do
      extend Base
    end

    # Data payload from GET /v2.2/lrn/{number}/{ani}.
    LrnLookupData = Data.define(:ani, :destination, :lrn) do
      extend Base

      def self.nested
        { lrn: LrnData }
      end
    end

    # Carrier and line-type details. The wire object keeps the upstream
    # carrier lookup's field names — snake_case, not the API's usual
    # camelCase — so the members are pinned with wire_keys.
    CarrierDetails = Data.define(
      :name, :type, :mobile_country_code, :mobile_network_code, :error_code
    ) do
      extend Base

      def self.wire_keys
        {
          mobile_country_code: "mobile_country_code",
          mobile_network_code: "mobile_network_code",
          error_code: "error_code"
        }
      end
    end

    # Data payload from GET /v2.2/carrier/{number}. Billed per lookup at the
    # account's CNAM rate.
    CarrierData = Data.define(:number, :carrier) do
      extend Base

      def self.nested
        { carrier: CarrierDetails }
      end
    end
  end
end
