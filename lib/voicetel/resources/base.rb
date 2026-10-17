# frozen_string_literal: true

require "erb"

module VoiceTel
  module Resources
    # Shared base for every resource service. Each service receives the
    # client's transport on construction and uses it for HTTP calls. Keeping
    # this thin lets us keep resource files focused on their endpoints.
    class Base
      def initialize(transport)
        @transport = transport
      end

      # Compact a query hash, dropping nil and empty-string values, before
      # handing it to the transport. Some endpoints take a lot of optional
      # filters and writing `nil` everywhere at call sites would be noisy.
      def compact_query(hash)
        hash.reject { |_, v| v.nil? || v == "" }
      end

      # Percent-encode one URL path segment (RFC 3986: everything outside
      # a-z A-Z 0-9 _ - . ~ is escaped). Used for every interpolated path
      # parameter so user input can't break out of its segment.
      def escape_path(value)
        ERB::Util.url_encode(value.to_s)
      end

      # Request bodies accept either a plain Hash (snake_case keys) or a
      # Models request object; the transport only speaks Hashes.
      def payload(body)
        body.respond_to?(:to_payload) ? body.to_payload : body
      end
    end
  end
end
