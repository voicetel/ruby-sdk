# frozen_string_literal: true

require_relative "base"

module VoiceTel
  module Models
    # A single CIDR row used by the ACL endpoints. Masks must be /8, /16,
    # /24, or /32 and must describe a routable public address.
    CidrEntry = Data.define(:cidr) do
      extend Base
    end

    # Generic error body returned for non-2xx responses. The SDK raises
    # ApiError rather than returning this; the model exists so callers can
    # build one from ApiError#body when it carries a JSON payload.
    ErrorResponse = Data.define(:status, :code, :message, :error, :details) do
      extend Base
    end
  end
end
