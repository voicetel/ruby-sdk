# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # INumberingService — inventory searches, orders, and port-ins.
    #
    # PortAvailability returns the v2.2.10 fields `local_routing_number` and
    # `rate_center_tier` alongside `number`, `portable`, `losing_carrier`, `reason`.
    class INumbering < Base
      # GET /v2.2/inventory — search available TNs.
      #
      # @return [Models::InventorySearchData]
      def search_inventory(npa: nil, nxx: nil, state: nil, ratecenter: nil, contains: nil, endswith: nil, limit: nil)
        q = compact_query(
          "npa" => npa, "nxx" => nxx, "state" => state, "ratecenter" => ratecenter,
          "contains" => contains, "endswith" => endswith, "limit" => limit
        )
        Models::InventorySearchData.build(@transport.request(:get, "/v2.2/inventory", query: q))
      end

      # GET /v2.2/inventory/coverage — aggregated availability buckets.
      #
      # @return [Models::InventoryCoverageData]
      def coverage(state: nil, ratecenter: nil)
        q = compact_query("state" => state, "ratecenter" => ratecenter)
        Models::InventoryCoverageData.build(@transport.request(:get, "/v2.2/inventory/coverage", query: q))
      end

      # POST /v2.2/orders — purchase new TNs.
      #
      # @return [Models::OrderCreateData]
      def order(body)
        Models::OrderCreateData.build(@transport.request(:post, "/v2.2/orders", body: payload(body)))
      end

      # GET /v2.2/ports — list every port-in record.
      #
      # @return [Models::PortListData]
      def ports
        Models::PortListData.build(@transport.request(:get, "/v2.2/ports"))
      end

      # GET /v2.2/ports/{id} — detail for one port-in.
      #
      # @return [Models::PortDetailData]
      def port(id)
        Models::PortDetailData.build(@transport.request(:get, "/v2.2/ports/#{id}"))
      end

      # POST /v2.2/ports — submit a port-in.
      #
      # @return [Models::PortSubmitData]
      def submit_port(body)
        Models::PortSubmitData.build(@transport.request(:post, "/v2.2/ports", body: payload(body)))
      end

      # GET /v2.2/ports/availability/{number} — check whether a TN can be
      # ported in.
      #
      # @return [Models::PortAvailabilityData]
      def port_availability(number)
        Models::PortAvailabilityData.build(@transport.request(:get, "/v2.2/ports/availability/#{number}"))
      end
    end
  end
end
