# frozen_string_literal: true

module VoiceTel
  # The semantic version of the VoiceTel Ruby SDK. This tracks the API version
  # it targets (currently v2.2.10).
  VERSION = "2.2.10"

  # The VoiceTel REST API version this SDK targets.
  API_VERSION = "v2.2.10"

  # Default production API endpoint.
  DEFAULT_BASE_URL = "https://api.voicetel.com"

  # User-Agent header sent on every request unless overridden.
  USER_AGENT = "voicetel-ruby/#{VERSION} (+https://github.com/voicetel/ruby-sdk)".freeze
end
