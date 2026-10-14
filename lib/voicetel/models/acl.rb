# frozen_string_literal: true

require_relative "base"
require_relative "common"

module VoiceTel
  module Models
    # ------------------------------------------------------------- requests ---
    # Body for POST /v2.2/acl (add) and DELETE /v2.2/acl (remove). Entries
    # may be CidrEntry objects or plain { cidr: "..." } hashes.
    AclModifyRequest = Data.define(:acl) do
      include Request
    end

    # ------------------------------------------------------ response data ---
    # Data payload from GET /v2.2/acl.
    AclListData = Data.define(:acl) do
      extend Base

      def self.nested
        { acl: CidrEntry }
      end
    end

    # Data payload from POST /v2.2/acl.
    AclAddData = Data.define(:added) do
      extend Base

      def self.nested
        { added: CidrEntry }
      end
    end

    # Data payload from DELETE /v2.2/acl.
    AclRemoveData = Data.define(:removed) do
      extend Base

      def self.nested
        { removed: CidrEntry }
      end
    end

    # A CIDR that was rejected, with the reason. Appears in 409 bodies.
    AclFailedEntry = Data.define(:cidr, :reason) do
      extend Base
    end

    # Data payload included in a 409 response from POST/DELETE /v2.2/acl.
    # Surfaces both the entries that succeeded and the ones that failed, so
    # partial outcomes can be reconciled. Build one from ApiError#body.
    AclConflictData = Data.define(:added, :removed, :failed) do
      extend Base

      def self.nested
        { added: CidrEntry, removed: CidrEntry, failed: AclFailedEntry }
      end
    end
  end
end
