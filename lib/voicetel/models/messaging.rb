# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Models
    # ------------------------------------------------------------- requests ---
    # Body for POST /v2.2/messages — send an SMS or MMS. media_urls switches
    # the message type to MMS (and unlocks subject). Note the wire field
    # names fromNumber / toNumber.
    MessageSendRequest = Data.define(
      :from_number, :to_number, :text, :subject, :media_urls
    ) do
      include Request
    end

    # Body for POST /v2.2/messaging/brands.
    MessagingBrandCreateRequest = Data.define(
      :messaging_brand_id, :messaging_brand_name, :messaging_brand_description
    ) do
      include Request
    end

    # Body for POST /v2.2/messaging/campaigns. Passed through to the
    # campaign registration service; campaign_class_name (from the campaign
    # registry) and campaign_start_date (today) are auto-populated if
    # omitted.
    MessagingCampaignCreateRequest = Data.define(
      :messaging_brand_id, :external_campaign_id, :campaign_description,
      :campaign_class_name, :campaign_start_date
    ) do
      include Request
    end

    # ------------------------------------------------------ response data ---
    # Per-record fields inside MessageRecord. Shape varies by type:
    # sms/mms populate source_number, destination_number, direction, rate,
    # message; dlr populates source_number and destination_number only.
    MessageRecordValue = Data.define(
      :source_number, :destination_number, :direction, :rate, :number, :message
    ) do
      extend Base
    end

    # One row in MessageHistoryData.messages. key is a composite range key —
    # for sms/mms [destinationNumber, timestamp]; for dlr
    # [accountId, fromNumberWithCountryCode, timestamp] — with mixed types.
    MessageRecord = Data.define(:id, :key, :value) do
      extend Base

      def self.nested
        { value: MessageRecordValue }
      end
    end

    # Data payload from GET /v2.2/messages.
    MessageHistoryData = Data.define(:number, :type, :from_ts, :to_ts, :messages) do
      extend Base

      def self.nested
        { messages: MessageRecord }
      end
    end

    # Data payload from POST /v2.2/messages.
    MessageSendData = Data.define(
      :id, :type, :from_number, :to_number, :parts, :subject, :media_urls
    ) do
      extend Base
    end

    # Status payload for brand registration. status_code is the HTTP status
    # as a string; "200" on success.
    BrandRegistrationResult = Data.define(:status_code, :status) do
      extend Base
    end

    # Data payload from POST /v2.2/messaging/brands.
    MessagingBrandCreateData = Data.define(:result) do
      extend Base

      def self.nested
        { result: BrandRegistrationResult }
      end
    end

    # Status payload for campaign registration.
    CampaignRegistrationResult = Data.define(:status_code, :status) do
      extend Base
    end

    # Data payload from POST /v2.2/messaging/campaigns.
    MessagingCampaignCreateData = Data.define(:result) do
      extend Base

      def self.nested
        { result: CampaignRegistrationResult }
      end
    end

    # One carrier's latest DCA decision in CampaignDca. status is one of
    # ACTIVE, REJECTED, SUSPENDED, UNSUNSPENDED or TERMINATED; detail is the
    # reviewer's note, as given.
    CampaignDcaCarrier = Data.define(:carrier, :status, :detail, :updated_at) do
      extend Base
    end

    # Carrier (DCA) review progress for a campaign. nil for
    # CAMPAIGN_INVALID_ID statuses.
    CampaignDca = Data.define(:election_complete, :elected_carriers, :carriers) do
      extend Base

      def self.nested
        { carriers: CampaignDcaCarrier }
      end
    end

    # A single campaign and its current numbers. status is one of
    # CAMPAIGN_DCA_COMPLETE (ready: carrier review finished, numbers
    # assigned), CAMPAIGN_DCA_COMPLETE_NO_NUMBERS_ASSIGNED,
    # CAMPAIGN_PENDING_DCA (active at the campaign registry, but carrier
    # (DCA) review is not finished yet; numbers cannot be enabled until it
    # is), CAMPAIGN_DCA_REJECTED (a carrier's DCA rejected or suspended the
    # campaign; see dca.carriers), CAMPAIGN_<registry status>, or
    # CAMPAIGN_INVALID_ID.
    CampaignStatusItem = Data.define(:id, :status, :numbers, :dca) do
      extend Base

      def self.nested
        { dca: CampaignDca }
      end
    end

    # Data payload from GET /v2.2/messaging/campaigns.
    MessagingCampaignStatusData = Data.define(:campaigns) do
      extend Base

      def self.nested
        { campaigns: CampaignStatusItem }
      end
    end
  end
end
