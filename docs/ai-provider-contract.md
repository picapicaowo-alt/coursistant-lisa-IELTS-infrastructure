# Backend AI-provider contract

The infrastructure does not implement application AI behavior. This document
defines the boundary the backend team must implement before enabling an AI
provider.

## Runtime configuration

The `ai/provider` Secrets Manager value is a JSON object. The backend adapter
owns the exact provider SDK, but these canonical keys keep deployment portable:

| Key | Required | Purpose |
|---|---|---|
| `AI_PROVIDER` | Yes | `disabled`, an approved mainland provider identifier, or `openai` |
| `AI_BASE_URL` | Provider-dependent | Server-side provider endpoint |
| `AI_API_KEY` | Provider-dependent | Provider credential; never returned to the browser |
| `AI_MODEL` | Yes when enabled | Explicit allowlisted model/snapshot |
| `AI_TIMEOUT_MS` | Yes when enabled | End-to-end timeout, bounded by the backend |
| `AI_MAX_OUTPUT_TOKENS` | Yes when enabled | Per-request output ceiling |

Terraform separately sets `AI_PROVIDER_MODE`. The backend must refuse startup
when the secret's `AI_PROVIDER` conflicts with that mode. `disabled` must not
require or call any provider credential.

## Request boundary

- The browser calls only same-origin `/ai-agent` or `/study-support` routes.
- The authenticated backend derives tenant/user identity from the verified
  session; it does not accept a caller-supplied user ID as authority.
- Authorization happens before retrieving course/attachment evidence.
- Initial mainland testing excludes student names, contact information, grades,
  submissions, raw attachments, and unrestricted course-bucket reads.
- Provider payloads contain the minimum evidence needed for the task and an
  explicit purpose. Do not forward entire database records or logs.

## Reliability

- Support streaming without Nginx buffering.
- Use a total timeout, bounded connect/read timeouts, and at most two retries for
  explicitly retryable transport/provider errors.
- Never retry authentication, policy, validation, quota, or unsafe-content
  errors.
- Add a circuit breaker and a server-side kill switch that does not require a
  frontend release.
- Use idempotency keys for chargeable writes where the provider/API supports
  them; do not duplicate a response after a client reconnect.
- Non-AI Coursistant workflows remain available when AI is disabled, rate
  limited, timed out, or circuit-open.

## Audit without content leakage

Record tenant ID, opaque user ID, request ID, feature/workflow, provider, model,
start/end time, latency, token counts, outcome category, and cost estimate.
Prompts, responses, access tokens, provider keys, raw evidence, and attachment
contents are excluded from default logs.

## Acceptance evidence

Backend handoff is complete only after tests cover:

- AI-disabled behavior and non-AI fallback;
- authentication and tenant/record authorization;
- quota/rate limit, timeout, retry, circuit breaker, and kill switch;
- SSE disconnect/reconnect behavior;
- input/output size limits and content-safety response;
- log redaction and absence of student PII;
- provider error mapping without exposing provider internals or credentials.
