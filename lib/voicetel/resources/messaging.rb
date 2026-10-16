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

      # GET /v2.2/messaging/health — account-wide messaging health overview.
      #
      # Mirrors the portal Messaging tab: summary counts (numbers, messaging on,
      # healthy, needing attention, in progress), campaigns with carrier-review
      # progress, numbers needing attention (each with a plain-language title,
      # detail and the actions that fix it), 14 days of delivery counts, and the
      # alert-email setting. Updated hourly.
      #
      # The spec defines no response schema for this endpoint, so the unwrapped
      # JSON payload is returned verbatim as a raw Hash (no typed model).
      #
      # @return [Hash]
      def health
        @transport.request(:get, "/v2.2/messaging/health")
      end

      # GET /v2.2/messaging/health/alerts — the alert-email setting: whether new
      # messaging problems are emailed to the account.
      #
      # The spec defines no response schema, so the unwrapped payload is returned
      # verbatim as a raw Hash.
      #
      # @return [Hash]
      def health_alerts
        @transport.request(:get, "/v2.2/messaging/health/alerts")
      end

      # PUT /v2.2/messaging/health/alerts — turn alert emails on or off. When
      # enabled, the account is emailed as new messaging problems are found (at
      # most one digest about every 20 hours).
      #
      # The spec defines no response schema, so the unwrapped payload is returned
      # verbatim as a raw Hash.
      #
      # @param enabled [Boolean]
      # @return [Hash]
      def set_health_alerts(enabled:)
        @transport.request(:put, "/v2.2/messaging/health/alerts", body: { enabled: enabled })
      end

      # POST /v2.2/messaging/health/check — live health check of one number: in
      # service, messaging enabled, campaign approved, assigned to the campaign by
      # the messaging provider, delivery failures in the last 24 hours, and
      # enablement in progress. Limited to 30 checks per hour per account.
      #
      # The spec defines no response schema, so the unwrapped payload is returned
      # verbatim as a raw Hash.
      #
      # @param number [String] 10-digit number on the account
      # @return [Hash]
      def health_check(number:)
        @transport.request(:post, "/v2.2/messaging/health/check", body: { number: number })
      end

      # GET /v2.2/messaging/health/samples — up to 3 recent outbound messages from
      # the number that carriers blocked as spam (time, masked recipient, text,
      # reason), to help review content.
      #
      # The spec defines no response schema, so the unwrapped payload is returned
      # verbatim (raw Hash or Array).
      #
      # @param number [String] 10-digit number on the account
      # @return [Hash, Array]
      def health_samples(number:)
        @transport.request(:get, "/v2.2/messaging/health/samples", query: { number: number })
      end
    end
  end
end
