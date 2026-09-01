# Coursistant IELTS — AWS Tokyo infrastructure

Terraform and operational tooling for the isolated Coursistant IELTS testing
environment in AWS Asia Pacific (Tokyo), `ap-northeast-1`.

The initial target is a closed test of approximately 300 person-sessions. The
default compute size is `m7i.xlarge` (4 vCPU, 16 GiB), but concurrency tests—not
the participant count—are the authority for resizing.

## Important safety boundary

The stack is provider-neutral and deploys with `AI_PROVIDER_MODE=disabled`.
Putting a server in Tokyo does not make OpenAI available to mainland-China end
users. Terraform rejects `ai_provider_mode = "openai"` when
`mainland_end_users = true`, and also requires an explicit supported-user
confirmation for any OpenAI deployment.

No application secret value is managed in Terraform. Terraform creates empty
AWS Secrets Manager containers; authorized operators populate them out of band.

## What this repository creates

- A dedicated VPC across two Tokyo Availability Zones.
- Public subnets for an HTTPS Application Load Balancer and private application
  subnets with controlled outbound access.
- One `m7i.xlarge` EC2 instance by default, managed by Auto Scaling and Systems
  Manager. Port 22 is never opened.
- Nginx same-origin routing for `/api`, `/ai-agent`, and `/study-support`, plus
  immutable frontend/backend release directories.
- Private, encrypted, versioned S3 buckets for uploads, deployment artifacts,
  and audit logs.
- KMS, least-privilege instance IAM, Secrets Manager containers, CloudTrail,
  CloudWatch log groups and alarms, SNS, WAF, and a monthly AWS budget.
- A bootstrap stack for an encrypted Terraform state bucket and GitHub OIDC
  plan/apply roles.
- Release, rollback, smoke-test, and validation scripts for the backend team.

## Repository layout

```text
bootstrap/                 One-time state bucket and GitHub OIDC setup
environments/test/         Deployable Tokyo test environment
modules/                   Network, storage, compute, observability modules
scripts/                   Validation, release, rollback, and smoke tests
docs/                      Architecture, backend contract, runbooks, compliance
```

## Deployment sequence

1. Read [`docs/compliance-gates.md`](docs/compliance-gates.md) and record the
   approved AI-provider decision.
2. Run the one-time [`docs/bootstrap-runbook.md`](docs/bootstrap-runbook.md).
3. Configure the GitHub `test` environment and required repository variables.
4. Copy `environments/test/terraform.tfvars.example` to a non-committed
   `terraform.tfvars`, then provide the real domain, Route 53 zone, alert email,
   and approved CIDRs.
5. Run `make check`, review `terraform plan`, and apply only to the test AWS
   account.
6. Populate Secrets Manager without putting secret values in Terraform, GitHub
   source, shell arguments, or logs.
7. Hand the runtime interface in [`docs/backend-handoff.md`](docs/backend-handoff.md)
   and [`docs/ai-provider-contract.md`](docs/ai-provider-contract.md) to the
   backend team and deploy the first immutable artifact.
8. Complete [`docs/acceptance-checklist.md`](docs/acceptance-checklist.md).

## Local verification

Requires Terraform 1.10+, TFLint, and ShellCheck.

```bash
make check
```

No real `terraform plan` or `apply` is possible until an authorized AWS identity,
domain, hosted-zone ID, and account-specific backend configuration are supplied.
