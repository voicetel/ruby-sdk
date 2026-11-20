# Changelog

## Unreleased

### Added
- `:insufficient_balance` (HTTP 402 — fax send, directory listing) and `:payload_too_large` (HTTP 413 — fax documents over 8 MiB) error kinds, with the usual `ApiError#insufficient_balance?` / `#payload_too_large?` predicates. Both previously fell through to `:unknown`.

## 2.2.21 — 2026-11-20

Spec v2.2.21 audit release: the new Fax API and one breaking wire fix.

### Added
- **Fax API** (5 operations, tag `Fax`): `client.fax`
  - `numbers` — `GET /v2.2/numbers/fax`: every fax-capable number on the account with the email faxes to it deliver to (`destination_id` 0 = the account email).
  - `send_fax(from_number:, to_number:, documents:, idempotency_key:)` — `POST /v2.2/faxes` (HTTP 201): **multipart/form-data** with `fromNumber`/`toNumber` text fields and 1–10 `documents` file parts (PDF/DOC/DOCX, magic-byte checked server-side, 8 MiB each and in total). Idempotent per the client-generated **UUID `Idempotency-Key`** — a fresh one is generated when omitted; pass the same key with the same documents to get the original job back instead of a second send. Documents are part hashes (`name`, `content` as raw bytes, optional `content_type` — guessed from the name) or bare file paths. Rate-limited to 10 sends/minute/account. Returns `Models::FaxSendData`.
  - `history(number:, from:, to:, limit:, cursor:, status:)` — `GET /v2.2/faxes`: cursor-paged jobs newest first (`Models::FaxHistoryData` / `Models::FaxJob`); `from`/`to` are unix seconds (from is the newer edge; defaults to the last 24 hours).
  - `get(id)` — `GET /v2.2/faxes/{id}`: one job (`Models::FaxJob`); poll until `status` is `"sent"` or `"failed"`.
  - `document(id)` — `GET /v2.2/faxes/{id}/document`: the rendered PDF as **raw bytes** (binary response, not parsed). Served when the job reports `document_available` true.
- Transport: a multipart/form-data request path (hand-built body, no new dependency), an `idempotency_key:` override for the auto-generated `Idempotency-Key`, and a `raw:` response mode for binary downloads.
- The fax error envelope adds `serverTime` beside `status`/`error` — parsed tolerantly (exposed on `ApiError#body`).

### Changed
- **Breaking**: `client.acl.remove` now sends the same JSON body as `add` — `{ acl: [{ cidr: "203.0.113.0/24" }] }` — instead of the removed `cidrs` query parameter (the server's v2.2.0 rewrite reads the body only). 409 bodies still carry `data.removed` / `data.failed` on `ApiError#body`.

## 2.2.20 — 2026-11-20

Spec v2.2.20 sync. Adds the four new operations and tracks the truth fixes from spec v2.2.18–v2.2.20.

### Added
- **Directory listing (411)** on a number: `client.numbers.get_directory_listing(number)`, `.set_directory_listing(number, body)`, `.remove_directory_listing(number)` — GET returns the published state (`listed` / `not_listed` / `pending` / `removing` / `unavailable`, `eligible`, `listing`, `pending`); PUT/DELETE are accepted at once (HTTP 202, applied in the background) with an `order_id`. The DELETE is one of the few that returns a body.
- **Carrier & line-type lookup**: `client.lookups.carrier(number)` — `Models::CarrierDetails` keeps the upstream field names (`mobile_country_code`, `mobile_network_code`, `error_code`, snake_case on the wire); billed per lookup at the account's CNAM rate.
- `Models::OrderCreateData.routes` — POST /v2.2/orders now returns the route each ordered number was placed on (`Models::OrderRoute`).

### Changed
- e911 `addressid` is a **string** (hex), not an integer, on both the validation response and `E911ProvisionByIdRequest`.
- `MessageSendRequest.text` is optional (media-only MMS is valid); `subject` is deprecated; `media_urls` must be non-empty.
- Message-history `value` records carry the full field set: `message_text`, `transaction_guid`, `concatenated_message` (dlr), `attachments`, `subject` (mms), `ip` (outbound sms).
- DID `route` fields accept any gateway id on the account in addition to the global routes; an unknown route is rejected by the API with 400.

## 2.2.17 — 2026-10-17

Spec v2.2.17 sync.

### Fixed
- DID `route` fields are documented as the global route enum (1 USER, 2 T30, 3 VOICE_BRIDGE, 4 DID (default), 5 T38, 6 VOICEML, 8 SDN, 9 MOBILE); examples that showed invalid values (0, 1000) corrected.
- Example data sanitized suite-wide (fiction-reserved 555-01xx phone numbers; no real names/addresses/campaign IDs); no API behavior change.

## 2.2.16 — 2026-10-17

Spec-conformance release tracking VoiceTel API spec v2.2.16. **Contains breaking changes** — request shapes now match the documented wire format.

### Breaking
- `login` / API-key exchange and sub-account create: `username` (and `masterAccount`) are now **strings** per spec.
- `GET /v2.2/inventory` search: parameters are `tnMask` (required), `quantity`, `province`, `rateCenter`, `lata`; the old `npa`/`nxx`/`state`/`ratecenter`/`contains`/`endswith`/`limit` params were removed.
- `GET /v2.2/inventory/coverage`: `countBy` (required; `state`/`city`/`rateCenter`/`npanxx`/`block`) plus `locState`/`city`/`rcAbbre`/`npa`/`lata`; the old `state`/`ratecenter` params were removed.
- `GET /v2.2/messages` history: parameters are `number` (required), `from`, `to`, `type`; `start`/`end` were removed.
- `GET /v2.2/messaging/campaigns`: the `ids` query parameter is now required.
- `DELETE /v2.2/numbers/{number}/messaging-campaign`: the `campaignId` query parameter is now required.
- `DELETE /v2.2/numbers/messaging-campaign` (bulk unassign): sends required `numbers` + `campaignId` **query** parameters; no request body.
- `DELETE /v2.2/acl`: sends the required `cidrs` query parameter; no request body.
- `GET /v2.2/numbers/messaging`: the `numbers` parameter is now required.
- `GET /v2.2/ports/{id}`: `id` is the 5-character pid **string**.
- `lata` filter parameters are strings, matching the response schemas.
- Message-history `value.number` is now a string (spec fix).

### Fixed
- API error envelope `{"status":"error","error":{"code":N,"message":"..."}}` is parsed correctly — `code` and `message` are populated instead of degrading to `HTTP <status>`.
- `POST /v2.2/accounts` (signup) no longer requires an API key, per spec.
- Honored `Retry-After` values are capped at 8 seconds (previously unbounded).
- Path parameters are URL-encoded.
- `GET /v2.2/account/credits` exposes the optional `status` filter; the tickets list includes `totalCount`; removed the nonexistent `expires` field from registration data.
- Docs: corrected the rate-limit list (GET `/v2.2/account`, `/account/cdr`, `/account/recurring-charges`, POST `/account/api-key` at 6/hr/IP; POST `/v2.2/messaging/health/check` at 30/hr/account) and the operation count (79).
- All Faraday errors (including SSL) and gzip failures are wrapped in `ApiError`.

## 2.2.15 — 2026-10-15

Sync with VoiceTel API spec v2.2.15.

### Messaging

- New **messaging health** surface (the same view as the portal Messaging tab).
  The spec defines no response schema for these endpoints, so each method returns
  the unwrapped JSON payload verbatim (a raw `Hash`/`Array`) rather than a typed
  `Models::…` Data object; only the request body/query is shaped.
  - `GET /v2.2/messaging/health` → `messaging.health` — account-wide overview:
    summary counts, campaigns with carrier-review progress, numbers needing
    attention (with fix-it actions), 14 days of delivery counts, and the
    alert-email setting. Updated hourly.
  - `GET /v2.2/messaging/health/alerts` → `messaging.health_alerts` — whether new
    messaging problems are emailed to the account.
  - `PUT /v2.2/messaging/health/alerts` → `messaging.set_health_alerts(enabled: …)`
    — turn alert emails on or off (at most one digest about every 20 hours).
  - `POST /v2.2/messaging/health/check` → `messaging.health_check(number: …)` — live
    check of one number (in service, messaging enabled, campaign approved, assigned
    by the provider, delivery failures in the last 24h, enablement in progress).
    Limited to 30 checks per hour per account.
  - `GET /v2.2/messaging/health/samples` → `messaging.health_samples(number: …)` — up
    to 3 recent outbound messages from the number that carriers blocked as spam.

## 2.2.14 — 2026-10-14

Sync with VoiceTel API spec v2.2.14.

### Messaging

- `GET /v2.2/messaging/campaigns` — campaign status items now carry `dca`,
  the carrier (DCA) review progress: `electionComplete` (every carrier has a
  DCA assigned), `electedCarriers` (DCAs assigned so far, null when
  unavailable), and `carriers[]` — the latest per-carrier decision
  (`carrier`, `status` of ACTIVE / REJECTED / SUSPENDED / UNSUSPENDED /
  TERMINATED, `detail`, `updatedAt`). `dca` is null for
  `CAMPAIGN_INVALID_ID`.
- Campaign `status` values documented: `CAMPAIGN_DCA_COMPLETE` (ready:
  carrier review finished, numbers assigned),
  `CAMPAIGN_DCA_COMPLETE_NO_NUMBERS_ASSIGNED`, `CAMPAIGN_PENDING_DCA`
  (registry-active but carrier review unfinished — numbers cannot be enabled
  yet), `CAMPAIGN_DCA_REJECTED` (see `dca.carriers`),
  `CAMPAIGN_<registry status>`, `CAMPAIGN_INVALID_ID`.
- `POST /v2.2/messaging/campaigns` — clarified that `campaignClassName` is
  auto-populated from the campaign registry and `campaignStartDate` defaults
  to today.

### This SDK

- Adds typed `Data.define` model classes for requests and responses
  (nested models serialize correctly inside arrays). Minimum Ruby is now
  3.2.
- RuboCop: eleven previously disabled cops re-enabled at zero findings;
  the remaining off-cops (`RSpec/SpecFilePathFormat`,
  `RSpec/NoExpectationExample`) carry explicit justifications.

## 2.2.11 — 2026-10-14 (backfilled)

Sync with VoiceTel API spec v2.2.11, which this SDK had not yet absorbed.

### Messaging / Numbers

- Async (path C) campaign enablement: new enablement-job model
  (`campaignId`, `state` of queued -> hosting -> assigning -> routing ->
  done | failed, `message`, `createdAt`, `updatedAt`).
- `GET /v2.2/numbers/{number}/messaging` — the state may now report network
  "C" and carries `pending` (the enablement job) while provisioning runs.
- `PUT /v2.2/numbers/{number}/messaging-campaign` — the result now reports
  `status` ("enabled" | "already" | "pending"), `alreadyAssigned`,
  `orderId` (path B only; null for path C), `message`, `warning`, and `job`
  (path C). Assign-network is now B/C; `previousNetwork` no longer reports
  "unknown". Path A campaigns are being migrated and take no new numbers.
- `PUT` assign now returns 202 with status "pending" for path C — poll the
  number's messaging state until the job is done or failed.

### Account / iNumbering

- `services.rcid` removed from account responses.
- `supportUrl` removed from port summaries.
- Port-out PIN update now reports `changed` — an existing PIN is locked for
  30 days once set and is returned unchanged.

### Authentication

- Auth-mode wording clarified: 0 = Digest, 1 = Lax (Digest | IP), 2 = IP,
  3 = Strict (Digest + IP).
