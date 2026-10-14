# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # SupportService — support tickets (create, read, update, delete, reply).
    #
    # On the wire, SupportConversation's `number` field is the ticket
    # sequence integer (1015, 2114, ...), NOT a phone number; the model
    # exposes it as Models::SupportConversation#ticket_number.
    class Support < Base
      # GET /v2.2/support/tickets — every ticket on the account.
      #
      # @return [Models::TicketsListData]
      def list
        Models::TicketsListData.build(@transport.request(:get, "/v2.2/support/tickets"))
      end

      # POST /v2.2/support/tickets — open a ticket.
      #
      # @return [Models::TicketData]
      def create(body)
        Models::TicketData.build(
          @transport.request(:post, "/v2.2/support/tickets", body: payload(body))
        )
      end

      # GET /v2.2/support/tickets/{id} — one ticket.
      #
      # @return [Models::TicketData]
      def get(id)
        Models::TicketData.build(@transport.request(:get, "/v2.2/support/tickets/#{id}"))
      end

      # PUT /v2.2/support/tickets/{id} — update a ticket.
      #
      # @return [Models::TicketUpdateData]
      def update(id, body)
        Models::TicketUpdateData.build(
          @transport.request(:put, "/v2.2/support/tickets/#{id}", body: payload(body))
        )
      end

      # DELETE /v2.2/support/tickets/{id}. Returns nil on 204 No Content.
      def delete(id)
        @transport.request(:delete, "/v2.2/support/tickets/#{id}")
      end

      # GET /v2.2/support/tickets/{id}/messages — the ticket's threads.
      #
      # @return [Models::TicketThreadsData]
      def messages(id)
        Models::TicketThreadsData.build(
          @transport.request(:get, "/v2.2/support/tickets/#{id}/messages")
        )
      end

      # POST /v2.2/support/tickets/{id}/replies — reply to a ticket.
      #
      # @return [Models::TicketReplyData]
      def reply(id, body)
        Models::TicketReplyData.build(
          @transport.request(:post, "/v2.2/support/tickets/#{id}/replies", body: payload(body))
        )
      end
    end
  end
end
