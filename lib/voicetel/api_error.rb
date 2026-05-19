# frozen_string_literal: true

module VoiceTel
  # ApiError is raised on every non-2xx response (and on transport failures).
  #
  # `kind` is a Symbol classifying the failure so callers can pattern-match
  # without checking HTTP status codes directly. The convenience predicates
  # (`rate_limit?`, `not_found?`, etc.) are exposed for readability.
  class ApiError < StandardError
    KINDS = %i[
      bad_request
      authentication
      permission_denied
      not_found
      conflict
      rate_limit
      server
      unknown
    ].freeze

    attr_reader :kind, :status_code, :code, :body

    def initialize(message, kind: :unknown, status_code: nil, code: nil, body: nil)
      super(message)
      @kind = kind
      @status_code = status_code
      @code = code
      @body = body
    end

    # Convenience predicates — one per kind.
    KINDS.each do |k|
      define_method("#{k}?") { @kind == k }
    end

    def self.kind_from_status(status)
      case status
      when 400 then :bad_request
      when 401 then :authentication
      when 403 then :permission_denied
      when 404 then :not_found
      when 409 then :conflict
      when 429 then :rate_limit
      when 500..599 then :server
      else :unknown
      end
    end

    def self.from_response(status, code, message, body)
      new(
        message,
        kind: kind_from_status(status),
        status_code: status,
        code: code,
        body: body
      )
    end
  end
end
