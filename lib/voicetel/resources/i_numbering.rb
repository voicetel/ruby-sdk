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
      # @param tn_mask [String] prefix or wildcard pattern: "201", "201555", "201555*" (required)
      # @param quantity [Integer, nil] max results, 1-1000 (server default 10)
      # @param province [String, nil] 2-letter US state or Canadian province code
      # @param rate_center [String, nil] rate-center name
      # @param lata [String, nil] LATA code
      # @return [Models::InventorySearchData]
      def search_inventory(tn_mask:, quantity: nil, province: nil, rate_center: nil, lata: nil)
        q = compact_query(
          "tnMask" => tn_mask, "quantity" => quantity, "province" => province,
          "rateCenter" => rate_center, "lata" => lata
        )
        Models::InventorySearchData.build(@transport.request(:get, "/v2.2/inventory", query: q))
      end

      # GET /v2.2/inventory/coverage — aggregated availability buckets.
      #
      # @param count_by [String] aggregation dimension: "state", "city",
      #   "rateCenter", "npanxx", or "block" (required)
      # @param loc_state [String, nil] state/province code filter (e.g. "NJ")
      # @param city [String, nil] city name filter
      # @param rc_abbre [String, nil] rate-center abbreviation filter
      # @param npa [String, nil] area-code filter (e.g. "201")
      # @param lata [String, nil] LATA code filter
      # @return [Models::InventoryCoverageData]
      def coverage(count_by:, loc_state: nil, city: nil, rc_abbre: nil, npa: nil, lata: nil)
        q = compact_query(
          "countBy" => count_by, "locState" => loc_state, "city" => city,
          "rcAbbre" => rc_abbre, "npa" => npa, "lata" => lata
        )
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
      # @param id [String] port-in record id
      # @return [Models::PortDetailData]
      def port(id)
        Models::PortDetailData.build(@transport.request(:get, "/v2.2/ports/#{escape_path(id)}"))
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
        Models::PortAvailabilityData.build(@transport.request(:get, "/v2.2/ports/availability/#{escape_path(number)}"))
      end
    end
  end
end
