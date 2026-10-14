# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # LookupsService — CNAM and LRN dips.
    #
    # Each call costs money; meter accordingly.
    class Lookups < Base
      # GET /v2.2/cnam/{number} — CNAM dip.
      #
      # @return [Models::CnamData]
      def cnam(number)
        Models::CnamData.build(@transport.request(:get, "/v2.2/cnam/#{number}"))
      end

      # GET /v2.2/lrn/{number}/{ani} — LRN dip.
      #
      # @return [Models::LrnLookupData]
      def lrn(number, ani)
        Models::LrnLookupData.build(@transport.request(:get, "/v2.2/lrn/#{number}/#{ani}"))
      end
    end
  end
end
