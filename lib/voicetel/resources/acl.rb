# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # AclService — manages the IP allowlist (CIDR entries).
    #
    # The DELETE /v2.2/acl endpoint is unusual: it returns 200 with a body
    # (not 204). 409 conflicts include partial success/failure detail in the
    # body — surfaced through ApiError#body so callers can inspect it (or
    # build a Models::AclConflictData from it).
    class Acl < Base
      # GET /v2.2/acl — the current allowlist.
      #
      # @return [Models::AclListData]
      def list
        Models::AclListData.build(@transport.request(:get, "/v2.2/acl"))
      end

      # POST /v2.2/acl — body example: { acl: [{ cidr: "1.2.3.0/24" }] }
      #
      # @return [Models::AclAddData]
      def add(body)
        Models::AclAddData.build(@transport.request(:post, "/v2.2/acl", body: payload(body)))
      end

      # DELETE /v2.2/acl — returns 200 with a body, not 204.
      #
      # @return [Models::AclRemoveData]
      def remove(body)
        Models::AclRemoveData.build(@transport.request(:delete, "/v2.2/acl", body: payload(body)))
      end
    end
  end
end
