# frozen_string_literal: true

require_relative "base"
require_relative "common"

module VoiceTel
  module Models
    # ------------------------------------------------------------- requests ---
    # Body for PUT /v2.2/auth — update authentication mode and/or password.
    # auth_type: 0=Digest, 1=Lax (Digest | IP), 2=IP, 3=Strict (Digest + IP).
    AuthPutRequest = Data.define(:auth_type, :password) do
      include Request
    end

    # ------------------------------------------------------ response data ---
    # Data payload from GET /v2.2/auth.
    AuthGetData = Data.define(:auth_type, :auth_type_description, :acl) do
      extend Base

      # auth_type — 0=Digest, 1=Lax (Digest | IP), 2=IP, 3=Strict (Digest + IP).
      def self.nested
        { acl: CidrEntry }
      end
    end

    # One field's change record, returned by PUT /v2.2/auth. field is
    # "authType" or "password"; value echoes the new setting when safe and
    # is nil for password.
    AuthUpdatedEntry = Data.define(:field, :value) do
      extend Base
    end

    # Data payload from PUT /v2.2/auth.
    AuthPutData = Data.define(:updated) do
      extend Base

      def self.nested
        { updated: AuthUpdatedEntry }
      end
    end

    # Data payload included in a 409 response from PUT /v2.2/auth — same
    # shape as AuthPutData. Build one from ApiError#body.
    AuthPutConflictData = Data.define(:updated) do
      extend Base

      def self.nested
        { updated: AuthUpdatedEntry }
      end
    end
  end
end
