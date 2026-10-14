# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # AuthenticationService — SIP/HTTP authentication settings (mode + password).
    #
    # auth_type values: 0=Digest, 1=Lax (Digest | IP), 2=IP, 3=Strict
    # (Digest + IP).
    class Authentication < Base
      AUTH_TYPE_DIGEST = 0
      AUTH_TYPE_LAX    = 1
      AUTH_TYPE_IP     = 2
      AUTH_TYPE_STRICT = 3

      # GET /v2.2/auth — the active auth mode.
      #
      # @return [Models::AuthGetData]
      def get
        Models::AuthGetData.build(@transport.request(:get, "/v2.2/auth"))
      end

      # PUT /v2.2/auth — update the auth mode and/or password.
      #
      # @return [Models::AuthPutData]
      def update(body)
        Models::AuthPutData.build(@transport.request(:put, "/v2.2/auth", body: payload(body)))
      end
    end
  end
end
