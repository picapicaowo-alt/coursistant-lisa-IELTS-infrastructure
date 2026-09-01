# AI closed-test approval and operational controls

This is an engineering control, not legal advice.

## Approved default

Coursistant approved OpenAI for the closed test on 2026-09-01. The environment
therefore defaults to `AI_PROVIDER_MODE=openai`. No AI provider credential is
created or populated by Terraform; an authorized operator stores it directly
in Secrets Manager.

## Approval record

Terraform no longer blocks the approved OpenAI test based on end-user
geography. This changes an engineering deployment control, not OpenAI's terms
or applicable law. OpenAI's published supported-country guidance currently
warns that accessing or offering access outside its list may lead to account
suspension; the accountable owner must retain any exception/approval evidence.

Before expanding the test, record:

1. The exact end-user countries are supported by OpenAI.
2. Coursistant has confirmed its account, payment method, and customer entity
   meet OpenAI requirements.
3. Privacy review covers prompt/response retention and international data
   transfer.
4. Student names, contact details, grades, submissions, and raw attachments are
   excluded unless a separately approved data flow permits them.
5. The approving owner, date, scope, participant limit, and emergency stop
   decision.

## Mainland pilot review

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
