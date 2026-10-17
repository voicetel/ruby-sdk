# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Models
    # ------------------------------------------------------------- requests ---
    # Body for POST /v2.2/orders. numbers holds up to 100 entries — plain
    # 10-digit strings or OrderNumberSpec objects for per-number routing.
    OrderCreateRequest = Data.define(:numbers) do
      include Request
    end

    # Per-number routing override inside OrderCreateRequest. route is the
    # global route type for numbers in this order: 1 USER, 2 T30,
    # 3 VOICE_BRIDGE, 4 DID (default), 5 T38, 6 VOICEML, 8 SDN, 9 MOBILE.
    OrderNumberSpec = Data.define(:number, :route) do
      include Request
    end

    # LIDB feature for a port-in TN.
    PortFeatureLidb = Data.define(:name) do
      include Request
    end

    # Routing feature for a port-in TN.
    PortFeatureRouting = Data.define(:gateway_id) do
      include Request
    end

    # SMS feature for a port-in TN.
    PortFeatureSms = Data.define(:campaign_id) do
      include Request
    end

    # Per-TN feature configuration applied after a port completes. routing,
    # lidb, and sms may be the matching feature objects or plain hashes.
    PortFeature = Data.define(:number, :routing, :lidb, :sms) do
      include Request
    end

    # Body for POST /v2.2/ports — submit a port-in order.
    PortSubmitRequest = Data.define(
      :did, :name, :name_type, :lc_btn, :lc_account_number, :street_number, :street,
      :street_type, :city, :state, :zip, :country, :auth_person, :street_prefix,
      :street_suffix, :floor, :room, :building, :unit_value, :desired_due_date, :pin,
      :features
    ) do
      include Request
    end

    # ------------------------------------------------- entities & data ---
    # A single TN available for assignment.
    InventoryItem = Data.define(:number, :rate_center, :city, :province, :lata) do
      extend Base
    end

    # One aggregated availability bucket. Which members are populated
    # depends on the countBy of the query.
    InventoryCoverageItem = Data.define(
      :count, :npa, :nxx, :block, :city, :rc_abbre, :lata, :loc_state
    ) do
      extend Base
    end

    # One row in the customer port-status list.
    PortSummary = Data.define(:status, :id, :pid, :foc, :created_at, :message) do
      extend Base
    end

    # Full detail for a single port-in record.
    PortDetail = Data.define(
      :status, :id, :pid, :name, :email, :foc, :created_at, :numbers, :message
    ) do
      extend Base
    end

    # ------------------------------------------------------ response data ---
    # Data payload from GET /v2.2/inventory.
    InventorySearchData = Data.define(:numbers) do
      extend Base

      def self.nested
        { numbers: InventoryItem }
      end
    end

    # Data payload from GET /v2.2/inventory/coverage.
    InventoryCoverageData = Data.define(:coverage) do
      extend Base

      def self.nested
        { coverage: InventoryCoverageItem }
      end
    end

    # One row in OrderCreateData.failed.
    OrderFailedEntry = Data.define(:number, :reason) do
      extend Base
    end

    # Data payload from POST /v2.2/orders. amount_charged is the amount
    # deducted from the account balance.
    OrderCreateData = Data.define(:order_id, :amount_charged, :numbers_ordered, :failed) do
      extend Base

      def self.nested
        { failed: OrderFailedEntry }
      end
    end

    # Data payload from GET /v2.2/ports.
    PortListData = Data.define(:ports) do
      extend Base

      def self.nested
        { ports: PortSummary }
      end
    end

    # Data payload from GET /v2.2/ports/{id}.
    PortDetailData = Data.define(:port) do
      extend Base

      def self.nested
        { port: PortDetail }
      end
    end

    # Data payload from POST /v2.2/ports.
    PortSubmitData = Data.define(:pid, :ticket, :message, :loa_url, :port_url) do
      extend Base
    end

    # Data payload from GET /v2.2/ports/availability/{number}.
    PortAvailabilityData = Data.define(
      :number, :portable, :losing_carrier, :local_routing_number, :rate_center_tier, :reason
    ) do
      extend Base
    end
  end
end
