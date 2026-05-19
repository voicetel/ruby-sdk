# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # LookupsService — CNAM and LRN dips.
    #
    # Each call costs money; meter accordingly.
    class Lookups < Base
      def cnam(number)
        @transport.request(:get, "/v2.2/cnam/#{number}")
      end

      def lrn(number, ani)
        @transport.request(:get, "/v2.2/lrn/#{number}/#{ani}")
      end
    end
  end
end
