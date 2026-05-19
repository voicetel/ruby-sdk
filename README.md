# 📞 VoiceTel Ruby SDK

The official Ruby client for the [VoiceTel REST API](https://voicetel.com/docs/api/v2.2/) — provision numbers, place orders, validate e911, send messages, and manage your account, all with idiomatic Ruby, structured errors, and zero codegen footprint.

![Version](https://img.shields.io/badge/version-2.2.10-blue)
![Ruby](https://img.shields.io/badge/ruby-3.1%2B-red)
![License](https://img.shields.io/badge/license-MIT-green)
![Coverage](https://img.shields.io/badge/coverage-%E2%89%A585%25-brightgreen)
![Gem](https://img.shields.io/badge/gem-voicetel-blue)

## 📚 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Quickstart](#-quickstart)
- [Authentication](#-authentication)
- [Resource Reference](#-resource-reference)
- [Error Handling](#-error-handling)
- [Rate Limits](#-rate-limits)
- [Development](#-development)
- [API Documentation](#-api-documentation)
- [Contributors](#-contributors)
- [Sponsors](#-sponsors)
- [License](#-license)

## ✨ Features

### 🧱 Idiomatic Ruby End-to-End
- **Resource-style API** — `client.numbers.list`, `client.messaging.send_message(...)`, just like the official SDKs in every other language.
- **snake_case everywhere**, automatically camelCased on the wire so the spec's `fromNumber` / `toNumber` / `messagingBrandId` look like plain Ruby.
- **RBS signatures** ship in `sig/` — opt into type-checking with Steep or Sorbet, or ignore them and stay dynamic.

### 🔁 Production-Grade Transport
- **Faraday 2.x** with connection pooling, persistent HTTP, and pluggable adapters.
- **Automatic retry** on 429 / 5xx via `faraday-retry`, honoring `Retry-After`.
- **Configurable timeouts** per client.
- **Bearer auth** managed for you; password→key exchange handled by `client.login`.
- **Structured ApiError** — `:rate_limit`, `:not_found`, `:conflict`, ... pattern-match on a Symbol, or call `err.rate_limit?`.

### 📞 Complete API Coverage
- **Numbers** — list, get, add, remove, route, translate, CNAM, LIDB, fax, forward, SMS, messaging campaigns, port-out PIN, account moves.
- **Account** — profile, sub-accounts, CDRs, credits, payments, MRC, registration, password recovery.
- **e911** — record provisioning, address validation, lookup, removal.
- **Gateways** — list, create, update, delete, view bound numbers.
- **Messaging** — SMS & MMS sending, message history, 10DLC brand and campaign registration, per-number messaging state.
- **Lookups** — CNAM and LRN dips.
- **iNumbering** — inventory search, coverage queries, number orders, port-in submissions, port-out availability checks (v2.2.10 LRN + rate-center tier fields).
- **Support** — ticket create / read / update / delete, threaded messages, replies.
- **ACL** — IP allowlist management with structured 409 conflict bodies.
- **Authentication** — switch between Digest, IP-only, or hybrid modes; rotate passwords.

### 🧪 Battle-Tested
- Unit tests against a mocked HTTP layer (`webmock`), every resource method covered.
- Read-only integration suite gated by env vars — safe for CI.
- ≥85% line coverage via `simplecov`.

## 🚀 Installation

```bash
gem install voicetel
```

Or in your `Gemfile`:

```ruby
gem "voicetel", "~> 2.2.10"
```

Requires Ruby 3.1 or later. Tested on 3.1, 3.2, 3.3, and 3.4.

## 🏁 Quickstart

```ruby
require "voicetel"

client = VoiceTel::Client.new

# Exchange username + password for an API key (one-time per session)
client.login(username: 1_000_000_001, password: "hunter2")

me = client.account.get
puts "Balance: $#{me['cash']}  |  Caller ID: #{me['callerId']}"

# List your numbers
client.numbers.list["numbers"].each do |n|
  puts "#{n['number']}  route=#{n['route']}  cnam=#{n['cnam']}  sms=#{n['smsEnabled']}"
end
```

Or, if you already have an API key:

```ruby
client = VoiceTel::Client.new(api_key: ENV.fetch("VOICETEL_API_KEY"))

coverage = client.i_numbering.coverage(state: "NJ")
coverage["coverage"].each do |bucket|
  puts "#{bucket['npa']}-#{bucket['nxx']}: #{bucket['count']} TNs available"
end
```

## 🔑 Authentication

Every endpoint requires `Authorization: Bearer <apikey>` **except** `POST /v2.2/account/api-key`, which exchanges username + password for a fresh key. `Client#login` handles the exchange and installs the returned key on the transport.

Re-fetch the API key after any password change — the old one is invalidated.

> Don't have credentials yet? Get them at **[voicetel.com/docs/api/v2.2/credentials](https://voicetel.com/docs/api/v2.2/credentials/)**.

```ruby
client = VoiceTel::Client.new
key = client.login(username: 1_000_000_001, password: "hunter2")
# `key` is the freshly minted bearer; the client already has it installed.
```

## 🗺️ Resource Reference

| Resource | Operations | Example |
|---|---|---|
| `client.account` | Profile, CDR, credits, payments, MRC, signup, recovery, sub-accounts | `client.account.cdr(start: t1, end_at: t2)` |
| `client.acl` | IP allowlist (CIDR entries) | `client.acl.add(acl: [{ cidr: "1.2.3.0/24" }])` |
| `client.authentication` | SIP/HTTP auth mode + password | `client.authentication.update(auth_type: 1)` |
| `client.e911` | Records, address validation, provisioning | `client.e911.validate(address1: "...", city: "...", state: "NJ", zip: "07101")` |
| `client.gateways` | Termination routes | `client.gateways.list` |
| `client.i_numbering` | Inventory, orders, port-ins | `client.i_numbering.search_inventory(npa: 201)` |
| `client.lookups` | CNAM & LRN dips | `client.lookups.lrn("2015551234", "2012548000")` |
| `client.messaging` | SMS/MMS, 10DLC brands & campaigns | `client.messaging.send_message(from_number: "...", to_number: "...", text: "...")` |
| `client.numbers` | All operations on TNs on the account | `client.numbers.assign_campaign("2015551234", campaign_id: "CABC123")` |
| `client.support` | Tickets, replies, attachments | `client.support.create(subject: "...", message: "...")` |

Every method that takes a body accepts a plain Ruby Hash with `snake_case` keys; the SDK camelCases them when serializing to JSON:

```ruby
client.messaging.send_message(
  from_number: "2012548000",
  to_number:   "2015551234",
  text:        "Your code is 482917"
)
# → POST /v2.2/messages { "fromNumber": "2012548000", "toNumber": "2015551234", "text": "Your code is 482917" }

client.numbers.assign_campaign("2015551234", campaign_id: "CABC123")
# → PUT /v2.2/numbers/2015551234/messaging-campaign { "campaignId": "CABC123" }
```

Responses come back as Hash/Array structures with the API's native (camelCase) keys — easy to pass straight to `to_json` or pretty-print.

## 🚨 Error Handling

All HTTP errors raise `VoiceTel::ApiError`. The `kind` attribute is a Symbol; convenience predicates are exposed for readability:

| Status | `kind`                | Predicate                |
|--------|-----------------------|--------------------------|
| 400    | `:bad_request`        | `err.bad_request?`       |
| 401    | `:authentication`     | `err.authentication?`    |
| 403    | `:permission_denied`  | `err.permission_denied?` |
| 404    | `:not_found`          | `err.not_found?`         |
| 409    | `:conflict`           | `err.conflict?`          |
| 429    | `:rate_limit`         | `err.rate_limit?`        |
| 5xx    | `:server`             | `err.server?`            |
| other  | `:unknown`            | `err.unknown?`           |

```ruby
begin
  client.numbers.get("9999999999")
rescue VoiceTel::ApiError => e
  case e.kind
  when :not_found    then puts "Not on your account."
  when :rate_limit   then puts "Slow down — retry suggested."
  when :authentication then puts "Re-login: #{e.message}"
  else raise
  end
end
```

`ApiError#body` preserves the parsed response payload — useful on 409 ACL conflicts, where the server returns structured `{added, removed, failed}` detail.

## ⏱️ Rate Limits

These endpoints are limited to **6 requests per hour per IP**:

- `account/info` (`client.account.get`)
- `account/cdr` (`client.account.cdr`)
- `account/recurring-charges` (`client.account.recurring_charges`)
- `account/payments` (`client.account.payments`)
- `account/registration` (`client.account.registration`)
- `account/api-key` (`client.login`)

The SDK automatically retries 429 responses with `Retry-After` honored, up to `max_retries` (default `2`). To raise it:

```ruby
VoiceTel::Client.new(api_key: key, max_retries: 4, timeout: 60)
```

## 🛠️ Development

```bash
git clone https://github.com/voicetel/ruby-sdk
cd ruby-sdk
bundle install

# Unit tests (fast, no network)
bundle exec rspec

# Lint
bundle exec rubocop

# Integration tests (live api.voicetel.com, read-only)
cp .env.example .env  # fill in VOICETEL_USERNAME / VOICETEL_PASSWORD
INTEGRATION=1 bundle exec rspec spec/integration

# Build the gem
gem build voicetel.gemspec
```

## 📖 API Documentation

- **Reference docs:** [voicetel.com/docs/api/v2.2/](https://voicetel.com/docs/api/v2.2/)
- **Interactive playground:** [voicetel.com/docs/api/v2.2/playground/](https://voicetel.com/docs/api/v2.2/playground/) — try the API in your browser without writing any code
- **API credentials:** [voicetel.com/docs/api/v2.2/credentials/](https://voicetel.com/docs/api/v2.2/credentials/)
- **Type signatures:** see `sig/voicetel.rbs`

## 🙌 Contributors

- [Michael Mavroudis](https://github.com/mavroudis) — Lead Developer

Contributions welcome. Open an issue describing the change you want to make, or send a pull request against `main`.

## 💖 Sponsors

| Sponsor | Contribution |
|---------|--------------|
| [VoiceTel Communications](https://voicetel.com) | Primary development and production hosting |

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
