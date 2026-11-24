# frozen_string_literal: true

require_relative "base"
require_relative "common"

module VoiceTel
  module Models
    # One fax-capable number on the account and the email address faxes to
    # it deliver to (the per-number fax destination, or — destination_id 0 —
    # the account email).
    FaxNumberEntry = Data.define(:number, :destination_id, :email) do
      extend Base
    end

    # Data payload from GET /v2.2/numbers/fax.
    FaxNumbersData = Data.define(:numbers) do
      extend Base

      def self.nested
        { numbers: FaxNumberEntry }
      end
    end

    # Metadata about one uploaded fax document.
    FaxDocumentMeta = Data.define(:name, :size, :content_type) do
      extend Base
    end

    # Data payload from POST /v2.2/faxes — the accepted (queued) job.
    FaxSendData = Data.define(:id, :from_number, :to_number, :status, :documents) do
      extend Base

      def self.nested
        { documents: FaxDocumentMeta }
      end
    end

    # One fax job: its routing, lifecycle timestamps (ISO-8601 UTC or nil),
    # delivery attempts and documents. status is queued / sending /
    # retry_pending / sent / failed. document_available gates
    # GET /v2.2/faxes/{id}/document.
    FaxJob = Data.define(
      :id, :from_number, :to_number, :client_token, :status,
      :submitted_at, :started_at, :completed_at, :attempts, :failure_reason,
      :documents, :document_available, :document_name, :document_size
    ) do
      extend Base

      def self.nested
        { documents: FaxDocumentMeta }
      end
    end

    # Data payload from GET /v2.2/faxes — one page of history, newest
    # first. next_cursor is opaque; pass it back as the next request's
    # cursor (nil on the last page).
    FaxHistoryData = Data.define(:number, :from_ts, :to_ts, :faxes, :next_cursor) do
      extend Base

      def self.nested
        { faxes: FaxJob }
      end
    end
  end
end
