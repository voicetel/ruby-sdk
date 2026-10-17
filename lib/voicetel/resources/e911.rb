# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Resources
    # E911Service — provisioning, validation, lookup, removal.
    #
    # Note: request bodies take a 10-digit TN in `dn`; responses return the
    # 11-digit E.164 US form (leading 1).
    class E911 < Base
      # GET /v2.2/e911 — every e911 record on the account.
      #
      # @return [Models::E911AllData]
      def list
        Models::E911AllData.build(@transport.request(:get, "/v2.2/e911"))
      end

      # POST /v2.2/e911 — validate and provision in one call.
      #
      # @return [Models::E911RecordData]
      def create(body)
        Models::E911RecordData.build(@transport.request(:post, "/v2.2/e911", body: payload(body)))
      end

      # POST /v2.2/e911/validations — validate an address without
      # provisioning it.
      #
      # @return [Models::E911ValidateData]
      def validate(body)
        Models::E911ValidateData.build(@transport.request(:post, "/v2.2/e911/validations", body: payload(body)))
      end

      # GET /v2.2/e911/{dn} — one record.
      #
      # @return [Models::E911RecordData]
      def get(dn)
        Models::E911RecordData.build(@transport.request(:get, "/v2.2/e911/#{escape_path(dn)}"))
      end

      # PUT /v2.2/e911/{dn} — provision with a previously-validated address.
      #
      # @return [Models::E911RecordData]
      def provision(dn, body)
        Models::E911RecordData.build(@transport.request(:put, "/v2.2/e911/#{escape_path(dn)}", body: payload(body)))
      end

      # DELETE /v2.2/e911/{dn}. Returns nil on 204 No Content.
      def remove(dn)
        @transport.request(:delete, "/v2.2/e911/#{escape_path(dn)}")
      end
    end
  end
end
