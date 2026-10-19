# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development, :test do
  gem "rake", "~> 13.0"
  gem "rspec", "~> 3.13"
  gem "simplecov", "~> 1.2", require: false
  gem "webmock", "~> 3.34"
end

# RuboCop's transitive deps (parallel, public_suffix, ...) require Ruby 3.3+,
# while the SDK itself requires only Ruby 3.2+ (Data models). Keep linting in
# its own group so the 3.2 matrix leg can skip it via
# `bundle config set --local without "lint"`.
group :lint do
  gem "rubocop", "~> 1.92"
  gem "rubocop-rspec", "~> 3.10"
end
