# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "faraday/net_http_persistent"
require "json"
require "securerandom"
require "stringio"
require "zlib"

require_relative "../api_error"
require_relative "../version"

module VoiceTel
  module Internal
    # Transport is the low-level Faraday wrapper used by every resource service.
    # It owns the connection, installs the bearer token, retries 429/5xx with
    # Retry-After honored, and strips the `{status, data}` envelope from
    # responses before returning the inner payload.
    class Transport
      RETRYABLE_STATUSES = [429, 500, 502, 503, 504].freeze

      attr_reader :base_url, :user_agent, :timeout, :max_retries
      attr_accessor :api_key

      def initialize(base_url:, api_key: nil, timeout: 30, max_retries: 2, user_agent: nil, adapter: nil)
        @base_url    = (base_url || VoiceTel::DEFAULT_BASE_URL).chomp("/")
        @api_key     = api_key
        @timeout     = timeout
        @max_retries = max_retries
        @user_agent  = user_agent || VoiceTel::USER_AGENT
        @adapter     = adapter
        @conn        = build_connection
      end

      # Perform an HTTP request. Returns the parsed inner data (envelope
      # stripped) on success, or raises ApiError on failure. Returns nil on
      # 204 No Content.
      #
      # @param method     [Symbol] one of :get, :post, :put, :patch, :delete
      # @param path       [String] absolute path including the /v2.2 prefix
      # @param query      [Hash, nil] query string params, snake_case keys
      # @param body       [Hash, nil] request body, snake_case keys (translated to camelCase)
      # @param require_auth [Boolean] false skips the bearer header
      def request(method, path, query: nil, body: nil, require_auth: true)
        if require_auth && (@api_key.nil? || @api_key.empty?)
          raise ApiError.new(
            "no api key set; call client.login(...) or pass api_key: to Client.new",
            kind: :authentication
          )
        end

        headers = build_headers(require_auth)
        headers["Idempotency-Key"] = SecureRandom.uuid if %i[post put patch].include?(method)
        response = @conn.run_request(method, path, body ? JSON.generate(camelize_keys(body)) : nil, headers) do |req|
          req.params.update(camelize_keys(query)) if query && !query.empty?
        end

        handle_response(response)
      rescue Faraday::TimeoutError => e
        raise ApiError.new("voicetel: request timed out: #{e.message}", kind: :unknown)
      rescue Faraday::ConnectionFailed => e
        raise ApiError.new("voicetel: connection failed: #{e.message}", kind: :unknown)
      end

      # Recursively transform a Ruby snake_case key Hash/Array structure into
      # a Hash with camelCase keys, suitable for JSON serialization. Values
      # that are already strings/numbers/bools/nil/symbols pass through.
      def camelize_keys(obj)
        case obj
        when Hash
          obj.each_with_object({}) do |(k, v), h|
            h[snake_to_camel(k)] = camelize_keys(v)
          end
        when Array
          obj.map { |v| camelize_keys(v) }
        else
          obj
        end
      end

      private

      def snake_to_camel(key)
        s = key.to_s
        return s unless s.include?("_")

        head, *rest = s.split("_")
        head + rest.map(&:capitalize).join
      end

      def build_connection
        Faraday.new(url: @base_url) do |f|
          f.request :retry, retry_options
          f.options.timeout      = @timeout
          f.options.open_timeout = @timeout
          f.adapter(@adapter || :net_http_persistent)
        end
      end

      def retry_options
        {
          max: @max_retries,
          interval: 0.5,
          interval_randomness: 0.0,
          backoff_factor: 2,
          max_interval: 8,
          retry_statuses: RETRYABLE_STATUSES,
          methods: %i[get post put patch delete],
          retry_if: ->(env, _exception) { RETRYABLE_STATUSES.include?(env.status) }
        }
      end

      def decode_body(response)
        raw = response.body.to_s
        encoding = response.headers["content-encoding"] || response.headers["Content-Encoding"]
        return raw unless encoding&.downcase&.include?("gzip")

        Zlib::GzipReader.new(StringIO.new(raw)).read
      end

      def build_headers(require_auth)
        h = {
          "User-Agent" => @user_agent,
          "Accept" => "application/json",
          "Accept-Encoding" => "gzip",
          "Content-Type" => "application/json"
        }
        h["Authorization"] = "Bearer #{@api_key}" if require_auth && @api_key && !@api_key.empty?
        h
      end

      def handle_response(response)
        status = response.status
        raw = decode_body(response)

        if status >= 200 && status < 300
          return nil if raw.empty? || status == 204

          parsed = parse_json(raw)
          return unwrap(parsed)
        end

        raise build_error(status, raw)
      end

      def parse_json(raw)
        return nil if raw.nil? || raw.empty?

        JSON.parse(raw)
      rescue JSON::ParserError
        raw
      end

      def unwrap(parsed)
        if parsed.is_a?(Hash) && parsed.key?("status") && parsed.key?("data")
          parsed["data"]
        else
          parsed
        end
      end

      def build_error(status, raw)
        parsed = parse_json(raw)
        code = nil
        message = nil

        if parsed.is_a?(Hash)
          code    = parsed["code"]    || parsed["error"]
          message = parsed["message"] || parsed["error"]
        end
        message ||= "HTTP #{status}"

        ApiError.from_response(status, code, "voicetel: HTTP #{status}: #{message}", parsed || raw)
      end
    end
  end
end
