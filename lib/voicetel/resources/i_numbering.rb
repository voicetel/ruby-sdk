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
      def search_inventory(npa: nil, nxx: nil, state: nil, ratecenter: nil, contains: nil, endswith: nil, limit: nil)
        q = compact_query(
          "npa" => npa, "nxx" => nxx, "state" => state, "ratecenter" => ratecenter,
          "contains" => contains, "endswith" => endswith, "limit" => limit
        )
        @transport.request(:get, "/v2.2/inventory", query: q)
      end

      # GET /v2.2/inventory/coverage — aggregated availability buckets.
      def coverage(state: nil, ratecenter: nil)
        q = compact_query("state" => state, "ratecenter" => ratecenter)
        @transport.request(:get, "/v2.2/inventory/coverage", query: q)
      end

      # POST /v2.2/orders — purchase new TNs.
      def order(body)
        @transport.request(:post, "/v2.2/orders", body: body)
      end

      # GET /v2.2/ports — list every port-in record.
      def ports
        @transport.request(:get, "/v2.2/ports")
      end

      # GET /v2.2/ports/{id} — detail for one port-in.
      def port(id)
        @transport.request(:get, "/v2.2/ports/#{id}")
      end

      # POST /v2.2/ports — submit a port-in.
      def submit_port(body)
        @transport.request(:post, "/v2.2/ports", body: body)
      end

      # GET /v2.2/ports/availability/{number} — check whether a TN can be ported in.
      def port_availability(number)
        @transport.request(:get, "/v2.2/ports/availability/#{number}")
      end
    end
  end
end
