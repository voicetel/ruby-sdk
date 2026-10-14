# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # GatewaysService — outbound termination gateways on the account.
    #
    # System route types: USER, T30, VOICEML, DID, T38, RTC_BRIDGE, SDN.
    class Gateways < Base
      # GET /v2.2/gateways — every gateway on the account.
      #
      # @return [Models::GatewaysListData]
      def list
        Models::GatewaysListData.build(@transport.request(:get, "/v2.2/gateways"))
      end

      # POST /v2.2/gateways — add a gateway.
      #
      # @return [Models::GatewayEntry]
      def add(body)
        Models::GatewayEntry.build(@transport.request(:post, "/v2.2/gateways", body: payload(body)))
      end

      # GET /v2.2/gateways/{id} — one gateway.
      #
      # @return [Models::GatewayEntry]
      def get(id)
        Models::GatewayEntry.build(@transport.request(:get, "/v2.2/gateways/#{id}"))
      end

      # PUT /v2.2/gateways/{id} — update a gateway.
      #
      # @return [Models::GatewayEntry]
      def update(id, body)
        Models::GatewayEntry.build(@transport.request(:put, "/v2.2/gateways/#{id}", body: payload(body)))
      end

      # DELETE /v2.2/gateways/{id}. Returns nil on 204 No Content.
      def remove(id)
        @transport.request(:delete, "/v2.2/gateways/#{id}")
      end

      # GET /v2.2/gateways/{id}/numbers — numbers bound to a gateway.
      #
      # @return [Models::GatewayNumbersData]
      def numbers(id)
        Models::GatewayNumbersData.build(@transport.request(:get, "/v2.2/gateways/#{id}/numbers"))
      end
    end
  end
end
