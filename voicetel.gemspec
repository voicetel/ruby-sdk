# frozen_string_literal: true

require_relative "lib/voicetel/version"

Gem::Specification.new do |spec|
  spec.name          = "voicetel"
  spec.version       = VoiceTel::VERSION
  spec.authors       = ["VoiceTel"]
  spec.email         = ["support@voicetel.com"]

  spec.summary       = "Official Ruby SDK for the VoiceTel REST API (v2.2.10)."
  spec.description   = "Idiomatic Ruby client for the VoiceTel REST API: provision numbers, " \
                       "place orders, validate e911, send SMS/MMS, manage 10DLC campaigns, and " \
                       "run support tickets, all with typed DTOs, structured errors, and " \
                       "automatic retry on 429/5xx."
  spec.homepage      = "https://voicetel.com/docs/api/v2.2/"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/voicetel/ruby-sdk",
    "bug_tracker_uri" => "https://github.com/voicetel/ruby-sdk/issues",
    "documentation_uri" => "https://voicetel.com/docs/api/v2.2/",
    "changelog_uri" => "https://github.com/voicetel/ruby-sdk/releases",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb", "sig/**/*.rbs", "LICENSE", "README.md", "voicetel.gemspec"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-retry", "~> 2.0"
end
