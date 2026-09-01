# Backend deployment handoff

## Infrastructure contract

The EC2 instance runs Amazon Linux 2023. Nginx accepts traffic from the ALB on
port 8080 and routes only to loopback services:

| Public prefix | Loopback target | Prefix behavior |
|---|---:|---|
| `/api/` | `127.0.0.1:8083` | Preserved |
| `/ai-agent/` | `127.0.0.1:8090` | Stripped |
| `/study-support/` | `127.0.0.1:8091` | Stripped |

These defaults are Terraform variables and may be changed only alongside the
backend contract and frontend proxy configuration.

The instance exposes no application port or SSH port publicly. Operations use
AWS Systems Manager Session Manager and Run Command.

## Backend release archive

Provide a gzip-compressed tar archive with this interface:

```text
release/
  bin/start       required, executable, remains in foreground
  bin/stop        optional, executable, idempotent
  bin/preflight   optional, executable, no mutation outside release directory
  bin/health      optional, executable, exits 0 only when ready
  ...application files...
```

`bin/start` is launched by systemd as the unprivileged `coursistant` user from
`/opt/coursistant/backend/current`. It must not daemonize. It may start a local
process supervisor or Docker Compose, but all externally routed listeners must
bind to `127.0.0.1`.

If `bin/health` is absent, the release manager checks
`http://127.0.0.1:8083/health`. A failed health check automatically restores
the `previous` symlink and restarts the prior release.

## Runtime environment

Before a restart, the release manager materializes the configured Secrets
Manager JSON objects into `/opt/coursistant/shared/runtime.env` with mode `0600`.
Keys must match `^[A-Z][A-Z0-9_]*$`; other keys are rejected.

Terraform always supplies these non-secret values:

| Variable | Meaning |
|---|---|
| `AWS_REGION` | Deployment region |
| `COURSISTANT_UPLOADS_BUCKET` | Private application-object bucket |
| `COURSISTANT_ARTIFACTS_BUCKET` | Immutable release bucket |
| `AI_PROVIDER_MODE` | `disabled`, `mainland-approved`, or gated `openai` |

The spelling of the `COURSISTANT_*` variables is intentional and stable for this
environment. Application-specific keys remain owned by the backend team.

Suggested secret separation:

- `backend/runtime`: database, authentication, mail, and application-only
  settings.
- `ai/provider`: provider base URL, model name, API key, and provider-specific
  settings. Leave it without a secret value while AI is disabled.

Use `scripts/put-secret-json.sh` to validate and upload a mode-`0600` JSON file
without printing its contents. Follow `docs/ai-provider-contract.md` for the AI
adapter interface.

Do not put secret values in Terraform variables, state, GitHub repository
variables, AMI/user data, release archives, or command-line arguments.

## S3 integration

The instance role can list the application buckets, read immutable artifacts,
and read/write objects in the uploads bucket. The backend must still authorize
each user and tenant before issuing a short-lived presigned URL.

Required application behavior:

- Keep object keys tenant- and record-scoped; do not accept raw client keys.
- Store object metadata/checksum in the application database.
- Delete an uploaded object when its database transaction fails.
- Never make a bucket/object public or place a bearer token in a URL.
- Set explicit content type, size limit, allowed extensions, and download name.

## First deployment

1. Populate the backend runtime secret using an approved secure workstation.
2. Package the release and calculate SHA-256.
3. Run `scripts/publish-backend-release.sh` with the environment prefix,
   artifact bucket, archive path, release ID, and SHA-256.
4. Wait for SSM command success.
5. Run `scripts/smoke-test.sh https://<test-domain>`.
6. Complete authenticated acceptance with designated synthetic accounts; a
   public health response alone is not business-flow acceptance.
