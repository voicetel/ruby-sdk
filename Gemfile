# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development, :test do
  gem "rake", "~> 13.0"
  gem "rspec", "~> 3.13"
  gem "simplecov", "~> 0.22", require: false
  gem "webmock", "~> 3.20"
end

# RuboCop's transitive deps (parallel, public_suffix, ...) require Ruby 3.3+,
# but the SDK itself supports Ruby 3.1+. Keep linting in its own group so the
# 3.1 / 3.2 matrix legs can skip it via `bundle config set --local without "lint"`.
group :lint do
  gem "rubocop", "~> 1.90"
  gem "rubocop-rspec", "~> 3.10"
end
