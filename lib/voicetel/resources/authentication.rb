# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # AuthenticationService — SIP/HTTP authentication settings (mode + password).
    #
    # auth_type values: 0 = Digest, 1 = IP Auth, 2 = Digest OR IP, 3 = Digest AND IP.
    class Authentication < Base
      AUTH_TYPE_DIGEST         = 0
      AUTH_TYPE_IP             = 1
      AUTH_TYPE_DIGEST_OR_IP   = 2
      AUTH_TYPE_DIGEST_AND_IP  = 3

      def get
        @transport.request(:get, "/v2.2/auth")
      end

      def update(body)
        @transport.request(:put, "/v2.2/auth", body: body)
      end
    end
  end
end
