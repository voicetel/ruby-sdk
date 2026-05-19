# frozen_string_literal: true

require_relative "voicetel/version"
require_relative "voicetel/api_error"
require_relative "voicetel/internal/transport"
require_relative "voicetel/resources/account"
require_relative "voicetel/resources/acl"
require_relative "voicetel/resources/authentication"
require_relative "voicetel/resources/e911"
require_relative "voicetel/resources/gateways"
require_relative "voicetel/resources/i_numbering"
require_relative "voicetel/resources/lookups"
require_relative "voicetel/resources/messaging"
require_relative "voicetel/resources/numbers"
require_relative "voicetel/resources/support"

# VoiceTel is the official Ruby SDK for the VoiceTel REST API.
#
# See:
# - https://voicetel.com/docs/api/v2.2/         — full API reference
# - https://voicetel.com/docs/api/v2.2/playground/ — interactive playground
# - https://voicetel.com/docs/api/v2.2/credentials/ — obtain credentials
module VoiceTel
  # Client is the entry point for the VoiceTel API. Construct with an API key
  # (or call #login to exchange username/password) and reach the API through
  # the resource accessors:
  #
  #   c = VoiceTel::Client.new(api_key: ENV.fetch("VOICETEL_API_KEY"))
  #   c.numbers.list
  #
  # Client is safe to share across threads as long as you don't reassign
  # the API key concurrently with in-flight requests.
  class Client
    attr_reader :transport

    def initialize(api_key: nil, base_url: nil, timeout: 30, max_retries: 2, user_agent: nil, adapter: nil)
      @transport = Internal::Transport.new(
        base_url: base_url,
        api_key: api_key,
        timeout: timeout,
        max_retries: max_retries,
        user_agent: user_agent,
        adapter: adapter
      )
    end

    # Exchange username + password for a 32-hex API key and install it on
    # this client. Shares the 6 req/hour/IP rate limit with the rest of the
    # account/* endpoints.
    #
    # @return [String] the freshly exchanged bearer token
    def login(username:, password:)
      data = @transport.request(
        :post, "/v2.2/account/api-key",
        body: { username: username, password: password },
        require_auth: false
      )
      key = data.is_a?(Hash) ? data["apikey"] : nil
      if key.nil? || key.empty?
        raise ApiError.new(
          "voicetel: api-key response did not contain data.apikey",
          kind: :authentication,
          body: data
        )
      end
      @transport.api_key = key
      key
    end

    # Currently installed bearer token (nil if none).
    def api_key
      @transport.api_key
    end

    # API endpoint this client is pointed at.
    def base_url
      @transport.base_url
    end

    # --- resource accessors ------------------------------------------------

    def account
      @account ||= Resources::Account.new(@transport)
    end

    def acl
      @acl ||= Resources::Acl.new(@transport)
    end

    def authentication
      @authentication ||= Resources::Authentication.new(@transport)
    end

    def e911
      @e911 ||= Resources::E911.new(@transport)
    end

    def gateways
      @gateways ||= Resources::Gateways.new(@transport)
    end

    def i_numbering
      @i_numbering ||= Resources::INumbering.new(@transport)
    end

    def lookups
      @lookups ||= Resources::Lookups.new(@transport)
    end

    def messaging
      @messaging ||= Resources::Messaging.new(@transport)
    end

    def numbers
      @numbers ||= Resources::Numbers.new(@transport)
    end

    def support
      @support ||= Resources::Support.new(@transport)
    end
  end
end
