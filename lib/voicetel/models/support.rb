# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Models
    # Note on SupportConversation#ticket_number: the OpenAPI spec types the
    # wire field `number` as an integer — it's the human-readable ticket
    # sequence (e.g. 1015), not a phone number. The model exposes it as
    # ticket_number so callers don't confuse it with TNs.

    # ------------------------------------------------------------- requests ---
    # Body for POST /v2.2/support/tickets.
    TicketCreateRequest = Data.define(:subject, :message, :email) do
      include Request
    end

    # Body for PUT /v2.2/support/tickets/{id}. status is "active",
    # "pending", "closed", or "spam".
    TicketUpdateRequest = Data.define(:status) do
      include Request
    end

    # Body for POST /v2.2/support/tickets/{id}/replies.
    TicketReplyRequest = Data.define(:message) do
      include Request
    end

    # --------------------------------------------------------- shared subtypes ---
    # Provenance of a ticket or thread.
    TicketSource = Data.define(:via, :type) do
      extend Base
    end

    # Action descriptor on a thread.
    TicketAction = Data.define(:text, :type) do
      extend Base
    end

    # createdBy / assignee / assignedTo / closedByUser shape.
    TicketActor = Data.define(
      :id, :type, :email, :first_name, :last_name, :photo_url
    ) do
      extend Base
    end

    # One custom-field row on a conversation.
    CustomFieldValue = Data.define(:id, :value, :text) do
      extend Base
    end

    # A single {id, value, type} entry under embedded emails/phones/
    # socialProfiles.
    CustomerContactEntry = Data.define(:id, :value, :type) do
      extend Base
    end

    # A single {id, value} entry under embedded.websites.
    CustomerWebsiteEntry = Data.define(:id, :value) do
      extend Base
    end

    # embedded.address shape on a support customer.
    CustomerAddress = Data.define(:street, :city, :state, :country, :zip) do
      extend Base
    end

    # embedded shape on SupportCustomer.
    CustomerEmbedded = Data.define(
      :address, :emails, :phones, :social_profiles, :websites
    ) do
      extend Base

      def self.nested
        { address: CustomerAddress, emails: CustomerContactEntry,
          phones: CustomerContactEntry, social_profiles: CustomerContactEntry,
          websites: CustomerWebsiteEntry }
      end
    end

    # -------------------------------------------------------------- attachments ---
    # One file attached to a support thread.
    SupportAttachment = Data.define(:id, :mime_type, :file_name, :file_url, :size) do
      extend Base
    end

    # embedded shape on SupportThread.
    ThreadEmbedded = Data.define(:attachments) do
      extend Base

      def self.nested
        { attachments: SupportAttachment }
      end
    end

    # embedded shape on SupportConversation — typically wraps threads.
    ConversationEmbedded = Data.define(:threads) do
      extend Base

      def self.nested
        { threads: SupportThread }
      end
    end

    # ----------------------------------------------------------------- entities ---
    # End-user profile attached to a support ticket.
    SupportCustomer = Data.define(
      :id, :first_name, :last_name, :email, :company, :job_title, :photo_type, :photo_url,
      :notes, :type, :created_at, :updated_at, :embedded
    ) do
      extend Base

      def self.nested
        { embedded: CustomerEmbedded }
      end
    end

    # One thread (message) within a ticket conversation. type is "customer"
    # (from the user), "message" (staff reply), or "note" (internal note).
    SupportThread = Data.define(
      :id, :status, :state, :type, :body, :rating, :rating_comment, :opened_at, :created_at,
      :source, :action, :created_by, :assigned_to, :customer, :to, :cc, :bcc, :embedded
    ) do
      extend Base

      def self.nested
        { source: TicketSource, action: TicketAction, created_by: TicketActor,
          assigned_to: TicketActor, customer: SupportCustomer, embedded: ThreadEmbedded }
      end
    end

    # A support ticket. Returned by GET /v2.2/support/tickets/{id} and as
    # the items of the list endpoint.
    SupportConversation = Data.define(
      :id, :ticket_number, :status, :state, :subject, :preview, :type, :mailbox_id,
      :folder_id, :threads_count, :closed_by, :closed_at, :created_at, :updated_at,
      :user_updated_at, :customer_waiting_since, :source, :created_by, :assignee,
      :closed_by_user, :customer, :cc, :bcc, :custom_fields, :embedded
    ) do
      extend Base

      def self.nested
        { source: TicketSource, created_by: TicketActor, assignee: TicketActor,
          closed_by_user: TicketActor, customer: SupportCustomer,
          custom_fields: CustomFieldValue, embedded: ConversationEmbedded }
      end

      def self.wire_keys
        { ticket_number: "number" }
      end
    end

    # ------------------------------------------------------ response data ---
    # Data payload from GET /v2.2/support/tickets/{id}.
    TicketData = Data.define(:ticket) do
      extend Base

      def self.nested
        { ticket: SupportConversation }
      end
    end

    # Data payload from GET /v2.2/support/tickets.
    TicketsListData = Data.define(:total_count, :tickets) do
      extend Base

      def self.nested
        { tickets: SupportConversation }
      end
    end

    # Data payload from GET /v2.2/support/tickets/{id}/messages.
    TicketThreadsData = Data.define(:messages) do
      extend Base

      def self.nested
        { messages: SupportThread }
      end
    end

    # Data payload from POST /v2.2/support/tickets/{id}/replies.
    TicketReplyData = Data.define(:message) do
      extend Base
    end

    # Data payload from PUT /v2.2/support/tickets/{id}.
    TicketUpdateData = Data.define(:id, :status) do
      extend Base
    end
  end
end
