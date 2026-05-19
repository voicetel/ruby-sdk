# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # AclService — manages the IP allowlist (CIDR entries).
    #
    # The DELETE /v2.2/acl endpoint is unusual: it returns 200 with a body
    # (not 204). 409 conflicts include partial success/failure detail in the
    # body — surfaced through ApiError#body so callers can inspect it.
    class Acl < Base
      def list
        @transport.request(:get, "/v2.2/acl")
      end

      # body example: { acl: [{ cidr: "1.2.3.0/24" }] }
      def add(body)
        @transport.request(:post, "/v2.2/acl", body: body)
      end

      def remove(body)
        @transport.request(:delete, "/v2.2/acl", body: body)
      end
    end
  end
end
