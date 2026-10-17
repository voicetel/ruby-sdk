# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Models
    # ------------------------------------------------------------- requests ---
    # Body for POST /v2.2/numbers. route is the global route type: 1 USER,
    # 2 T30, 3 VOICE_BRIDGE, 4 DID (default), 5 T38, 6 VOICEML, 8 SDN,
    # 9 MOBILE.
    NumberAddRequest = Data.define(:number, :route) do
      include Request
    end

    # Body for PUT /v2.2/numbers/{number}/route. route is the global route
    # type: 1 USER, 2 T30, 3 VOICE_BRIDGE, 4 DID (default), 5 T38, 6 VOICEML,
    # 8 SDN, 9 MOBILE.
    NumberRouteRequest = Data.define(:route) do
      include Request
    end

    # Body for PUT /v2.2/numbers/{number}/cnam — inbound CNAM toggle.
    NumberCnamRequest = Data.define(:enabled) do
      include Request
    end

    # Body for PUT /v2.2/numbers/{number}/lidb — outbound caller name.
    NumberLidbRequest = Data.define(:cnam, :customer_order_reference) do
      include Request
    end

    # Body for PUT /v2.2/numbers/{number}/fax.
    NumberFaxRequest = Data.define(:email) do
      include Request
    end

    # Body for PUT /v2.2/numbers/{number}/forward.
    NumberForwardRequest = Data.define(:destination) do
      include Request
    end

    # Body for PUT /v2.2/numbers/{number}/translation.
    NumberTranslationRequest = Data.define(:translation) do
      include Request
    end

    # Body for PUT /v2.2/numbers/{number}/sms. type is "email", "webhook",
    # or "sip"; resource is the matching destination.
    NumberSmsRequest = Data.define(:type, :resource) do
      include Request
    end

    # Body for PATCH /v2.2/numbers/{number}/messaging — update inbound
    # and/or outbound routing. route_in must be a numbers_sms row id owned
    # by the authenticated account, or 0 to detach. route_out is the
    # outbound carrier id — 0 (outbound off) or the route the number is
    # enabled on; to move a number to another campaign or messaging path
    # use PUT /v2.2/numbers/{number}/messaging-campaign.
    NumberMessagingPatchRequest = Data.define(:route_in, :route_out) do
      include Request
    end

    # Body for PUT /v2.2/numbers/{number}/messaging-campaign.
    NumberCampaignAssignRequest = Data.define(:campaign_id) do
      include Request
    end

    # Body for PATCH /v2.2/numbers/{number} — move to another account. route
    # is the global route type on the destination account: 1 USER, 2 T30,
    # 3 VOICE_BRIDGE, 4 DID (default), 5 T38, 6 VOICEML, 8 SDN, 9 MOBILE.
    NumberMoveRequest = Data.define(:account_id, :route) do
      include Request
    end

    # Body for PATCH /v2.2/numbers/{number}/port-out-pin.
    PortOutPinUpdateRequest = Data.define(:pin) do
      include Request
    end

    # ------------------------------------------------- entities & data ---
    # Per-number routing / feature state. Returned by GET /v2.2/numbers and
    # GET /v2.2/numbers/{number}. route is the global route type: 1 USER,
    # 2 T30, 3 VOICE_BRIDGE, 4 DID (default), 5 T38, 6 VOICEML, 8 SDN,
    # 9 MOBILE.
    NumberDetail = Data.define(
      :number, :translated, :route, :gateway, :cnam, :forward, :forward_to, :carrier,
      :sms_enabled, :fax_enabled
    ) do
      extend Base
    end

    # The campaign bound to a number, with its CSP-side status.
    CampaignBinding = Data.define(:id, :network, :status, :upstream_cnp_id) do
      extend Base
    end

    # State of an asynchronous (path C) enablement. Attached to a campaign
    # assignment (status "pending") or surfaced by
    # GET /v2.2/numbers/{number}/messaging while provisioning is in flight.
    # state is one of queued, hosting, assigning, routing, done, or failed
    # (queued -> hosting -> assigning -> routing -> done, or failed — see
    # message; the number keeps its previous routing until done).
    MessagingEnablementJob = Data.define(
      :campaign_id, :state, :message, :created_at, :updated_at
    ) do
      extend Base
    end

    # Current messaging routing state for one number.
    #
    # network — messaging path the number is currently on ("A", "B", or
    # "C"); nil when carrier is 0 or any non-messaging carrier. pending —
    # async path-C enablement in progress, nil when none.
    NumberMessagingState = Data.define(
      :number, :on_account, :enabled, :carrier, :route_in, :resource, :network, :campaign,
      :pending
    ) do
      extend Base

      def self.nested
        { campaign: CampaignBinding, pending: MessagingEnablementJob }
      end
    end

    # Data payload from POST /v2.2/numbers. route is the global route type
    # that was installed: 1 USER, 2 T30, 3 VOICE_BRIDGE, 4 DID (default),
    # 5 T38, 6 VOICEML, 8 SDN, 9 MOBILE.
    NumberAddData = Data.define(:number, :route) do
      extend Base
    end

    # Data payload from PUT /v2.2/numbers/{number}/cnam.
    NumberCnamData = Data.define(:number, :cnam) do
      extend Base
    end

    # Data payload from GET/PUT /v2.2/numbers/{number}/fax.
    NumberFaxData = Data.define(:number, :email) do
      extend Base
    end

    # Data payload from PUT /v2.2/numbers/{number}/forward.
    NumberForwardData = Data.define(:number, :forward_to) do
      extend Base
    end

    # Data payload from PUT /v2.2/numbers/{number}/lidb.
    NumberLidbData = Data.define(:number, :cnam, :customer_order_reference, :carrier_status) do
      extend Base
    end

    # Data payload from PATCH /v2.2/numbers/{number}/messaging. updated is
    # the subset of {routeIn, routeOut} the request changed.
    NumberMessagingPatchData = Data.define(:number, :updated) do
      extend Base
    end

    # Data payload from PATCH /v2.2/numbers/{number}. route is the global
    # route type on the destination account: 1 USER, 2 T30, 3 VOICE_BRIDGE,
    # 4 DID (default), 5 T38, 6 VOICEML, 8 SDN, 9 MOBILE.
    NumberMoveData = Data.define(:number, :account_id, :route) do
      extend Base
    end

    # Data payload from PUT /v2.2/numbers/{number}/route. route echoes the
    # applied global route type: 1 USER, 2 T30, 3 VOICE_BRIDGE, 4 DID
    # (default), 5 T38, 6 VOICEML, 8 SDN, 9 MOBILE.
    NumberRouteData = Data.define(:number, :route) do
      extend Base
    end

    # Data payload from GET/PUT /v2.2/numbers/{number}/sms.
    NumberSmsData = Data.define(:number, :type, :resource) do
      extend Base
    end

    # Data payload from PUT /v2.2/numbers/{number}/translation.
    NumberTranslationData = Data.define(:number, :translation) do
      extend Base
    end

    # Data payload from PUT /v2.2/numbers/{number}/messaging-campaign —
    # the result of binding a single number to a 10DLC campaign.
    #
    # status — "enabled" = bound now (path B); "already" = the number was
    # already bound to this campaign (records reconciled, no new order);
    # "pending" = accepted and being provisioned (path C) — poll
    # GET /v2.2/numbers/{number}/messaging (pending) until state is done or
    # failed.
    #
    # network — messaging path the campaign resolves to (from the CSP
    # sharing record): "B" (assigned synchronously) or "C" (provisioned
    # asynchronously, status "pending").
    #
    # upstream_cnp_id — CNP ID from the CSP sharing record: CAMP003 = path
    # B, BANDW = path C. (Campaigns on path A, CAMP004, are being migrated
    # and take no new numbers.)
    #
    # carrier — outbound carrier id the number routes through once enabled
    # (19 = path B, 1 = path C). For a pending path-C enablement the number
    # keeps its current routing until provisioning completes.
    #
    # already_assigned — true when the number was already bound to this
    # campaign on the target messaging path; records are reconciled and no
    # new network order is placed.
    #
    # order_id — network order id created for a path-B assignment. nil for
    # path C (see job), idempotent no-ops, and assignments confirmed without
    # a new order.
    #
    # previous_network — messaging path the number was bound to before this
    # call ("A" or "B"), nil if there was no prior binding.
    #
    # warning — non-fatal condition detected during the assignment (for
    # example a stale registration on the other messaging path whose removal
    # has been requested).
    #
    # message — human-readable note for a pending enablement.
    #
    # job — async path-C enablement job, nil otherwise.
    NumberMessagingCampaignAssignData = Data.define(
      :number, :campaign_id, :status, :network, :upstream_cnp_id, :carrier,
      :already_assigned, :order_id, :previous_network, :previous_network_cleared,
      :warning, :message, :job
    ) do
      extend Base

      def self.nested
        { job: MessagingEnablementJob }
      end
    end

    # Data payload from DELETE /v2.2/numbers/{number}/messaging-campaign.
    NumberMessagingCampaignUnassignData = Data.define(
      :number, :campaign_id, :network, :upstream_cnp_id, :unassigned
    ) do
      extend Base
    end

    # One row in the failure list returned by bulk unassign.
    CampaignUnassignFailure = Data.define(:number, :reason) do
      extend Base
    end

    # Data payload from DELETE /v2.2/numbers/messaging-campaign (bulk).
    NumbersMessagingCampaignUnassignData = Data.define(
      :campaign_id, :network, :upstream_cnp_id, :unassigned_numbers, :failed
    ) do
      extend Base

      def self.nested
        { failed: CampaignUnassignFailure }
      end
    end

    # Data payload from GET /v2.2/numbers.
    NumbersListData = Data.define(:numbers) do
      extend Base

      def self.nested
        { numbers: NumberDetail }
      end
    end

    # Data payload from GET /v2.2/numbers/messaging.
    NumbersMessagingListData = Data.define(:numbers) do
      extend Base

      def self.nested
        { numbers: NumberMessagingState }
      end
    end

    # Data payload from PATCH /v2.2/numbers/{number}/port-out-pin.
    #
    # The call is idempotent: a PIN is locked for 30 days once set, so a
    # number that already has one returns it unchanged with changed=false;
    # both cases return HTTP 200.
    #
    # number — ten-digit telephone number whose PIN is reported.
    # port_out_pin — the port-out PIN now on file for this number (the value
    # just set, or the existing value if the number was already locked).
    # changed — true if this request set the PIN; false if the number
    # already had one, which is locked for 30 days once set and is returned
    # unchanged.
    PortOutPinUpdateData = Data.define(:number, :port_out_pin, :changed) do
      extend Base
    end
  end
end
