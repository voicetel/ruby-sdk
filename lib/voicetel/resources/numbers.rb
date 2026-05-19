# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # NumbersService — every operation on a TN owned by the account.
    #
    # Most methods take the 10-digit TN as the first argument. Methods that
    # return 204 No Content return nil. The two exceptions in this resource
    # — DELETE /v2.2/numbers/{n}/messaging-campaign and
    # DELETE /v2.2/numbers/messaging-campaign — return 200 with a body and
    # are exposed via #unassign_campaign and #bulk_unassign_campaign.
    class Numbers < Base
      def list
        @transport.request(:get, "/v2.2/numbers")
      end

      def add(body)
        @transport.request(:post, "/v2.2/numbers", body: body)
      end

      def get(number)
        @transport.request(:get, "/v2.2/numbers/#{number}")
      end

      # Returns nil on 204 No Content.
      def remove(number)
        @transport.request(:delete, "/v2.2/numbers/#{number}")
      end

      # PATCH /v2.2/numbers/{number} — move a TN to another account.
      def move(number, body)
        @transport.request(:patch, "/v2.2/numbers/#{number}", body: body)
      end

      # POST /v2.2/numbers/{number}/release — release a TN back to the network.
      def release(number)
        @transport.request(:post, "/v2.2/numbers/#{number}/release")
      end

      def set_route(number, body)
        @transport.request(:put, "/v2.2/numbers/#{number}/route", body: body)
      end

      def set_translation(number, body)
        @transport.request(:put, "/v2.2/numbers/#{number}/translation", body: body)
      end

      def set_cnam(number, body)
        @transport.request(:put, "/v2.2/numbers/#{number}/cnam", body: body)
      end

      def set_lidb(number, body)
        @transport.request(:put, "/v2.2/numbers/#{number}/lidb", body: body)
      end

      def get_fax(number)
        @transport.request(:get, "/v2.2/numbers/#{number}/fax")
      end

      def set_fax(number, body)
        @transport.request(:put, "/v2.2/numbers/#{number}/fax", body: body)
      end

      # Returns nil on 204 No Content.
      def remove_fax(number)
        @transport.request(:delete, "/v2.2/numbers/#{number}/fax")
      end

      def set_forward(number, body)
        @transport.request(:put, "/v2.2/numbers/#{number}/forward", body: body)
      end

      # Returns nil on 204 No Content.
      def remove_forward(number)
        @transport.request(:delete, "/v2.2/numbers/#{number}/forward")
      end

      def get_sms(number)
        @transport.request(:get, "/v2.2/numbers/#{number}/sms")
      end

      def set_sms(number, body)
        @transport.request(:put, "/v2.2/numbers/#{number}/sms", body: body)
      end

      # Returns nil on 204 No Content.
      def remove_sms(number)
        @transport.request(:delete, "/v2.2/numbers/#{number}/sms")
      end

      def get_messaging(number)
        @transport.request(:get, "/v2.2/numbers/#{number}/messaging")
      end

      def patch_messaging(number, body)
        @transport.request(:patch, "/v2.2/numbers/#{number}/messaging", body: body)
      end

      def assign_campaign(number, body)
        @transport.request(:put, "/v2.2/numbers/#{number}/messaging-campaign", body: body)
      end

      # Returns response data (200 with body, not 204).
      def unassign_campaign(number)
        @transport.request(:delete, "/v2.2/numbers/#{number}/messaging-campaign")
      end

      # Returns response data (200 with body, not 204).
      def bulk_unassign_campaign(numbers)
        @transport.request(:delete, "/v2.2/numbers/messaging-campaign", body: { numbers: numbers })
      end

      def set_port_out_pin(number, body)
        @transport.request(:patch, "/v2.2/numbers/#{number}/port-out-pin", body: body)
      end
    end
  end
end
