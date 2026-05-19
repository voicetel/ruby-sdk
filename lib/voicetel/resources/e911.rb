# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # E911Service — provisioning, validation, lookup, removal.
    #
    # Note: request bodies take a 10-digit TN in `dn`; responses return the
    # 11-digit E.164 US form (leading 1).
    class E911 < Base
      def list
        @transport.request(:get, "/v2.2/e911")
      end

      def create(body)
        @transport.request(:post, "/v2.2/e911", body: body)
      end

      def validate(body)
        @transport.request(:post, "/v2.2/e911/validations", body: body)
      end

      def get(dn)
        @transport.request(:get, "/v2.2/e911/#{dn}")
      end

      def provision(dn, body)
        @transport.request(:put, "/v2.2/e911/#{dn}", body: body)
      end

      # Returns nil on 204 No Content.
      def remove(dn)
        @transport.request(:delete, "/v2.2/e911/#{dn}")
      end
    end
  end
end
