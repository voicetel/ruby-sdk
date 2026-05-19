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
      def history(number: nil, start: nil, end_at: nil, type: nil)
        q = compact_query(
          "number" => number,
          "start" => start,
          "end" => end_at,
          "type" => type
        )
        @transport.request(:get, "/v2.2/messages", query: q)
      end

      # POST /v2.2/messages — send an SMS or MMS.
      def send_message(body)
        @transport.request(:post, "/v2.2/messages", body: body)
      end

      # POST /v2.2/messaging/brands — register a 10DLC brand.
      def create_brand(body)
        @transport.request(:post, "/v2.2/messaging/brands", body: body)
      end

      # GET /v2.2/messaging/campaigns — current 10DLC campaign statuses.
      def campaign_status
        @transport.request(:get, "/v2.2/messaging/campaigns")
      end

      # POST /v2.2/messaging/campaigns — register a 10DLC campaign.
      def create_campaign(body)
        @transport.request(:post, "/v2.2/messaging/campaigns", body: body)
      end

      # GET /v2.2/numbers/messaging — messaging state for many numbers.
      # Pass an empty array (or omit) for "all numbers on the account".
      def numbers_state(numbers: nil)
        q = compact_query(
          "numbers" => (numbers && !numbers.empty? ? Array(numbers).join(",") : nil)
        )
        @transport.request(:get, "/v2.2/numbers/messaging", query: q)
      end
    end
  end
end
