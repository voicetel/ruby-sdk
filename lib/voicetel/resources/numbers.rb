# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # NumbersService — every operation on a TN owned by the account.
    #
    # Most methods take the 10-digit TN as the first argument. Methods that
    # return 204 No Content return nil. The exceptions in this resource —
    # DELETE /v2.2/numbers/{n}/messaging-campaign and
    # DELETE /v2.2/numbers/messaging-campaign (200 with a body) and
    # DELETE /v2.2/numbers/{n}/directory-listing (202, applied in the
    # background) — return a body and are exposed via #unassign_campaign,
    # #bulk_unassign_campaign and #remove_directory_listing.
    class Numbers < Base
      # GET /v2.2/numbers — every TN on the account.
      #
      # @return [Models::NumbersListData]
      def list
        Models::NumbersListData.build(@transport.request(:get, "/v2.2/numbers"))
      end

      # POST /v2.2/numbers — attach a TN to the account.
      #
      # @return [Models::NumberAddData]
      def add(body)
        Models::NumberAddData.build(@transport.request(:post, "/v2.2/numbers", body: payload(body)))
      end

      # GET /v2.2/numbers/{number} — routing/feature state for one TN.
      #
      # @return [Models::NumberDetail]
      def get(number)
        Models::NumberDetail.build(@transport.request(:get, "/v2.2/numbers/#{escape_path(number)}"))
      end

      # DELETE /v2.2/numbers/{number}. Returns nil on 204 No Content.
      def remove(number)
        @transport.request(:delete, "/v2.2/numbers/#{escape_path(number)}")
      end

      # PATCH /v2.2/numbers/{number} — move a TN to another account.
      #
      # @return [Models::NumberMoveData]
      def move(number, body)
        Models::NumberMoveData.build(@transport.request(:patch, "/v2.2/numbers/#{escape_path(number)}", body: payload(body)))
      end

      # POST /v2.2/numbers/{number}/release — release a TN back to the
      # network. Returns nil on 204 No Content.
      def release(number)
        @transport.request(:post, "/v2.2/numbers/#{escape_path(number)}/release")
      end

      # PUT /v2.2/numbers/{number}/route.
      #
      # @return [Models::NumberRouteData]
      def set_route(number, body)
        Models::NumberRouteData.build(
          @transport.request(:put, "/v2.2/numbers/#{escape_path(number)}/route", body: payload(body))
        )
      end

      # PUT /v2.2/numbers/{number}/translation.
      #
      # @return [Models::NumberTranslationData]
      def set_translation(number, body)
        Models::NumberTranslationData.build(
          @transport.request(:put, "/v2.2/numbers/#{escape_path(number)}/translation", body: payload(body))
        )
      end

      # PUT /v2.2/numbers/{number}/cnam — inbound CNAM toggle.
      #
      # @return [Models::NumberCnamData]
      def set_cnam(number, body)
        Models::NumberCnamData.build(
          @transport.request(:put, "/v2.2/numbers/#{escape_path(number)}/cnam", body: payload(body))
        )
      end

      # PUT /v2.2/numbers/{number}/lidb — outbound caller name.
      #
      # @return [Models::NumberLidbData]
      def set_lidb(number, body)
        Models::NumberLidbData.build(
          @transport.request(:put, "/v2.2/numbers/#{escape_path(number)}/lidb", body: payload(body))
        )
      end

      # GET /v2.2/numbers/{number}/fax.
      #
      # @return [Models::NumberFaxData]
      def get_fax(number)
        Models::NumberFaxData.build(@transport.request(:get, "/v2.2/numbers/#{escape_path(number)}/fax"))
      end

      # PUT /v2.2/numbers/{number}/fax.
      #
      # @return [Models::NumberFaxData]
      def set_fax(number, body)
        Models::NumberFaxData.build(
          @transport.request(:put, "/v2.2/numbers/#{escape_path(number)}/fax", body: payload(body))
        )
      end

      # DELETE /v2.2/numbers/{number}/fax. Returns nil on 204 No Content.
      def remove_fax(number)
        @transport.request(:delete, "/v2.2/numbers/#{escape_path(number)}/fax")
      end

      # PUT /v2.2/numbers/{number}/forward.
      #
      # @return [Models::NumberForwardData]
      def set_forward(number, body)
        Models::NumberForwardData.build(
          @transport.request(:put, "/v2.2/numbers/#{escape_path(number)}/forward", body: payload(body))
        )
      end

      # DELETE /v2.2/numbers/{number}/forward. Returns nil on 204 No Content.
      def remove_forward(number)
        @transport.request(:delete, "/v2.2/numbers/#{escape_path(number)}/forward")
      end

      # GET /v2.2/numbers/{number}/sms.
      #
      # @return [Models::NumberSmsData]
      def get_sms(number)
        Models::NumberSmsData.build(@transport.request(:get, "/v2.2/numbers/#{escape_path(number)}/sms"))
      end

      # PUT /v2.2/numbers/{number}/sms.
      #
      # @return [Models::NumberSmsData]
      def set_sms(number, body)
        Models::NumberSmsData.build(
          @transport.request(:put, "/v2.2/numbers/#{escape_path(number)}/sms", body: payload(body))
        )
      end

      # DELETE /v2.2/numbers/{number}/sms. Returns nil on 204 No Content.
      def remove_sms(number)
        @transport.request(:delete, "/v2.2/numbers/#{escape_path(number)}/sms")
      end

      # GET /v2.2/numbers/{number}/messaging — current messaging routing
      # state, including an async path-C enablement job in `pending` while
      # one is in flight.
      #
      # @return [Models::NumberMessagingState]
      def get_messaging(number)
        Models::NumberMessagingState.build(@transport.request(:get, "/v2.2/numbers/#{escape_path(number)}/messaging"))
      end

      # PATCH /v2.2/numbers/{number}/messaging — update inbound and/or
      # outbound routing.
      #
      # @return [Models::NumberMessagingPatchData]
      def patch_messaging(number, body)
        Models::NumberMessagingPatchData.build(
          @transport.request(:patch, "/v2.2/numbers/#{escape_path(number)}/messaging", body: payload(body))
        )
      end

      # PUT /v2.2/numbers/{number}/messaging-campaign — bind a number to a
      # 10DLC campaign. The campaign must be available to the account and
      # ACTIVE; the number is enabled on the messaging path the campaign
      # lives on. Idempotent: a number already bound to the campaign reports
      # status "already". Path-B assignments complete synchronously (status
      # "enabled"); path-C assignments are provisioned asynchronously
      # (status "pending" — poll #get_messaging until pending.state is
      # "done" or "failed").
      #
      # @return [Models::NumberMessagingCampaignAssignData]
      def assign_campaign(number, body)
        Models::NumberMessagingCampaignAssignData.build(
          @transport.request(:put, "/v2.2/numbers/#{escape_path(number)}/messaging-campaign", body: payload(body))
        )
      end

      # DELETE /v2.2/numbers/{number}/messaging-campaign — returns 200 with
      # a body, not 204.
      #
      # @param number [String] 10-digit TN on the account
      # @param campaign_id [String] TCR campaign id the number is being removed from (required)
      # @return [Models::NumberMessagingCampaignUnassignData]
      def unassign_campaign(number, campaign_id:)
        Models::NumberMessagingCampaignUnassignData.build(
          @transport.request(:delete, "/v2.2/numbers/#{escape_path(number)}/messaging-campaign",
                             query: { "campaignId" => campaign_id })
        )
      end

      # DELETE /v2.2/numbers/messaging-campaign — bulk unassign; returns 200
      # with a body, not 204. No request body: both parameters travel in the
      # query string.
      #
      # @param numbers [Array<String>] 10-digit TNs to remove (max 1000)
      # @param campaign_id [String] TCR campaign id the numbers are removed from (required)
      # @return [Models::NumbersMessagingCampaignUnassignData]
      def bulk_unassign_campaign(numbers:, campaign_id:)
        q = { "numbers" => Array(numbers).join(","), "campaignId" => campaign_id }
        Models::NumbersMessagingCampaignUnassignData.build(
          @transport.request(:delete, "/v2.2/numbers/messaging-campaign", query: q)
        )
      end

      # PATCH /v2.2/numbers/{number}/port-out-pin — set the port-out PIN.
      # Idempotent: a PIN already on file is locked for 30 days and returned
      # unchanged with changed=false.
      #
      # @return [Models::PortOutPinUpdateData]
      def set_port_out_pin(number, body)
        Models::PortOutPinUpdateData.build(
          @transport.request(:patch, "/v2.2/numbers/#{escape_path(number)}/port-out-pin", body: payload(body))
        )
      end

      # GET /v2.2/numbers/{number}/directory-listing — the 411 listing
      # state as published: status (listed / not_listed / pending /
      # removing / unavailable), eligible, the published listing and any
      # pending submission.
      #
      # @return [Models::DirectoryListingData]
      def get_directory_listing(number)
        Models::DirectoryListingData.build(
          @transport.request(:get, "/v2.2/numbers/#{escape_path(number)}/directory-listing")
        )
      end

      # PUT /v2.2/numbers/{number}/directory-listing — add or replace the
      # 411 listing. Accepted at once and applied in the background: returns
      # HTTP 202 with status "pending" and the carrier order reference in
      # order_id; poll #get_directory_listing until it settles.
      #
      # @return [Models::DirectoryListingData]
      def set_directory_listing(number, body)
        Models::DirectoryListingData.build(
          @transport.request(:put, "/v2.2/numbers/#{escape_path(number)}/directory-listing", body: payload(body))
        )
      end

      # DELETE /v2.2/numbers/{number}/directory-listing — remove the
      # published listing, or cancel a pending add. Returns 202 with a body
      # (status "removing" with an order_id, or "not_listed" when a pending
      # add was cancelled), not 204.
      #
      # @return [Models::DirectoryListingData]
      def remove_directory_listing(number)
        Models::DirectoryListingData.build(
          @transport.request(:delete, "/v2.2/numbers/#{escape_path(number)}/directory-listing")
        )
      end
    end
  end
end
