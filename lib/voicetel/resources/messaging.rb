# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # MessagingService — SMS/MMS sending and 10DLC brand/campaign registration.
    #
    # The message-send wire body uses `fromNumber` / `toNumber`. Pass those
    # snake_case in your Ruby hash (`from_number`, `to_number`) and the
    # transport will translate them when serializing.
    class Messaging < Base
      # GET /v2.2/messages — fetch message history.
      #
      # @return [Models::MessageHistoryData]
      def history(number: nil, start: nil, end_at: nil, type: nil)
        q = compact_query(
          "number" => number,
          "start" => start,
          "end" => end_at,
          "type" => type
        )
        Models::MessageHistoryData.build(@transport.request(:get, "/v2.2/messages", query: q))
      end

      # POST /v2.2/messages — send an SMS or MMS.
      #
      # @return [Models::MessageSendData]
      def send_message(body)
        Models::MessageSendData.build(@transport.request(:post, "/v2.2/messages", body: payload(body)))
      end

      # POST /v2.2/messaging/brands — register a 10DLC brand.
      #
      # @return [Models::MessagingBrandCreateData]
      def create_brand(body)
        Models::MessagingBrandCreateData.build(
          @transport.request(:post, "/v2.2/messaging/brands", body: payload(body))
        )
      end

      # GET /v2.2/messaging/campaigns — current 10DLC campaign statuses,
      # including carrier (DCA) review progress per campaign.
      #
      # @return [Models::MessagingCampaignStatusData]
      def campaign_status
        Models::MessagingCampaignStatusData.build(@transport.request(:get, "/v2.2/messaging/campaigns"))
      end

      # POST /v2.2/messaging/campaigns — register a 10DLC campaign. The body
      # is passed through to the campaign registration service;
      # campaignClassName (from the campaign registry) and
      # campaignStartDate (today) are auto-populated if omitted.
      #
      # @return [Models::MessagingCampaignCreateData]
      def create_campaign(body)
        Models::MessagingCampaignCreateData.build(
          @transport.request(:post, "/v2.2/messaging/campaigns", body: payload(body))
        )
      end

      # GET /v2.2/numbers/messaging — messaging state for many numbers.
      # Pass an empty array (or omit) for "all numbers on the account".
      #
      # @return [Models::NumbersMessagingListData]
      def numbers_state(numbers: nil)
        q = compact_query(
          "numbers" => (numbers && !numbers.empty? ? Array(numbers).join(",") : nil)
        )
        Models::NumbersMessagingListData.build(@transport.request(:get, "/v2.2/numbers/messaging", query: q))
      end
    end
  end
end
