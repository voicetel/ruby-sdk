# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # GatewaysService — outbound termination gateways on the account.
    class Gateways < Base
      def list
        @transport.request(:get, "/v2.2/gateways")
      end

      def add(body)
        @transport.request(:post, "/v2.2/gateways", body: body)
      end

      def get(id)
        @transport.request(:get, "/v2.2/gateways/#{id}")
      end

      def update(id, body)
        @transport.request(:put, "/v2.2/gateways/#{id}", body: body)
      end

      # Returns nil on 204 No Content.
      def remove(id)
        @transport.request(:delete, "/v2.2/gateways/#{id}")
      end

      def numbers(id)
        @transport.request(:get, "/v2.2/gateways/#{id}/numbers")
      end
    end
  end
end
