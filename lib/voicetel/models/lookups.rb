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
  end
end
