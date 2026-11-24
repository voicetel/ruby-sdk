# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # LookupsService — CNAM, carrier & line-type, and LRN dips.
    #
    # Each call costs money; meter accordingly.
    class Lookups < Base
      # GET /v2.2/cnam/{number} — CNAM dip.
      #
      # @return [Models::CnamData]
      def cnam(number)
        Models::CnamData.build(@transport.request(:get, "/v2.2/cnam/#{escape_path(number)}"))
      end

      # GET /v2.2/carrier/{number} — carrier and line-type dip. Billed per
      # lookup at the account's CNAM rate. The carrier object keeps the
      # upstream lookup's snake_case field names
      # (mobile_country_code / mobile_network_code / error_code).
      #
      # @return [Models::CarrierData]
      def carrier(number)
        Models::CarrierData.build(@transport.request(:get, "/v2.2/carrier/#{escape_path(number)}"))
      end

      # GET /v2.2/lrn/{number}/{ani} — LRN dip.
      #
      # @return [Models::LrnLookupData]
      def lrn(number, ani)
        Models::LrnLookupData.build(@transport.request(:get, "/v2.2/lrn/#{escape_path(number)}/#{escape_path(ani)}"))
      end
    end
  end
end
