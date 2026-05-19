# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  enable_coverage :line
  minimum_coverage_by_file 0
end

require "webmock/rspec"
WebMock.disable_net_connect!(allow_localhost: false)

require "voicetel"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.mock_with :rspec do |m|
    m.verify_partial_doubles = true
  end
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.warnings = false

  # Integration tests are tagged :integration and skipped by default.
  config.filter_run_excluding integration: true unless ENV["INTEGRATION"] == "1"
end

# Helpers shared by every resource spec.
module SpecHelpers
  BASE_URL = "https://api.voicetel.com"
  API_KEY = "f" * 32

  def new_client(api_key: API_KEY, **kwargs)
    VoiceTel::Client.new(api_key: api_key, base_url: BASE_URL, max_retries: 0, **kwargs)
  end

  def envelope(data)
    { status: "success", data: data }.to_json
  end
end

RSpec.configure { |c| c.include SpecHelpers }
