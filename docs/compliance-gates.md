# AI and mainland-China compliance gates

This is an engineering control, not legal advice.

## Default

`AI_PROVIDER_MODE=disabled`. No AI provider credential is created or populated
by Terraform.

## OpenAI gate

Do not set `ai_provider_mode = "openai"` for mainland-China end users. Terraform
will reject that combination. A Tokyo EC2 address does not change the location
of Coursistant end users or make an unsupported geography supported.

OpenAI can be selected only when all of the following are recorded:

1. The exact end-user countries are supported by OpenAI.
2. Coursistant has confirmed its account, payment method, and customer entity
   meet OpenAI requirements.
3. Privacy review covers prompt/response retention and international data
   transfer.
4. Student names, contact details, grades, submissions, and raw attachments are
   excluded unless a separately approved data flow permits them.
5. `openai_supported_end_users_confirmed = true` is approved in review.

## Mainland pilot gate

For a mainland-China pilot, select a provider that is contractually and
operationally available for that use. Before enabling it, document:

- whether the pilot is internal research or offered to the public;
- personal-information roles, consent/legal basis, retention, deletion, and
  cross-border transfer;
- content-safety, complaint, minor-protection, and human-escalation controls;
- applicable filing, assessment, labeling, or licensing requirements;
- a kill switch and tested non-AI fallback.

## Runtime controls

- Provider keys are server-side Secrets Manager values only.
- Log provider name, model identifier, latency, token counts, request ID, and
  outcome; do not log prompt/response bodies by default.
- Apply tenant/user quotas, request size limits, timeouts, bounded retries,
  circuit breaking, and model allowlists in the backend.
- The AI path must fail closed. The rest of Coursistant must remain usable when
  the provider is disabled or unavailable.
