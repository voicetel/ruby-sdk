# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Models
    # ------------------------------------------------------------- requests ---
    # Body for POST /v2.2/gateways.
    GatewayAddRequest = Data.define(:gateway, :prefix, :limit) do
      include Request
    end

    # Body for PUT /v2.2/gateways/{id}.
    GatewayUpdateRequest = Data.define(:gateway, :prefix, :limit) do
      include Request
    end

    # -------------------------------------------------- entities & data ---
    # A single gateway row. gateway holds an IP:port for customer gateways
    # or a system route name (USER, T30, VOICEML, DID, T38, RTC_BRIDGE, SDN)
    # for built-in routes; limit is nil on system routes.
    GatewayEntry = Data.define(:id, :gateway, :prefix, :limit, :system) do
      extend Base
    end

    # One number bound to a gateway, as returned by
    # GET /v2.2/gateways/{id}/numbers.
    GatewayNumberSummary = Data.define(
      :number, :translated, :forward, :forward_to, :cnam, :carrier, :sms_enabled, :fax_enabled
    ) do
      extend Base
    end

    # Data payload from GET /v2.2/gateways.
    GatewaysListData = Data.define(:gateways) do
      extend Base

      def self.nested
        { gateways: GatewayEntry }
      end
    end

    # Data payload from GET /v2.2/gateways/{id}/numbers.
    GatewayNumbersData = Data.define(:numbers) do
      extend Base

      def self.nested
        { numbers: GatewayNumberSummary }
      end
    end
  end
end
