# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # SupportService — support tickets (create, read, update, delete, reply).
    #
    # On the wire, SupportConversation.number is a ticket sequence integer
    # (1015, 2114, ...), NOT a phone number. When the spec uses `number`
    # in this context, that's the ticket id.
    class Support < Base
      def list
        @transport.request(:get, "/v2.2/support/tickets")
      end

      def create(body)
        @transport.request(:post, "/v2.2/support/tickets", body: body)
      end

      def get(id)
        @transport.request(:get, "/v2.2/support/tickets/#{id}")
      end

      def update(id, body)
        @transport.request(:put, "/v2.2/support/tickets/#{id}", body: body)
      end

      # Returns nil on 204 No Content.
      def delete(id)
        @transport.request(:delete, "/v2.2/support/tickets/#{id}")
      end

      def messages(id)
        @transport.request(:get, "/v2.2/support/tickets/#{id}/messages")
      end

      def reply(id, body)
        @transport.request(:post, "/v2.2/support/tickets/#{id}/replies", body: body)
      end
    end
  end
end
