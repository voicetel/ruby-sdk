# frozen_string_literal: true

module VoiceTel
  module Resources
    # Shared base for every resource service. Each service receives the
    # client's transport on construction and uses it for HTTP calls. Keeping
    # this thin lets us keep resource files focused on their endpoints.
    class Base
      def initialize(transport)
        @transport = transport
      end

      # Compact a query hash, dropping nil and empty-string values, before
      # handing it to the transport. Some endpoints take a lot of optional
      # filters and writing `nil` everywhere at call sites would be noisy.
      def compact_query(hash)
        hash.reject { |_, v| v.nil? || v == "" }
      end
    end
  end
end
