# Test environment deploy and rollback

## Infrastructure deployment

Local operators may use a partial S3 backend configuration:

```bash
cd environments/test
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend.hcl
terraform plan -out=test.tfplan
terraform apply test.tfplan
```

Never apply an unreviewed plan. Confirm the AWS account and region before every
apply. This repository authorizes only the `test` environment.

GitHub Actions provides the normal path after bootstrap. Pull requests run
format, validation, lint, and security checks. The manually dispatched deploy
workflow assumes the OIDC role for the protected `test` environment.

## Application release

Backend and frontend releases are immutable. The server keeps timestamped
directories plus atomic `current` and `previous` symlinks. The server-side
release manager verifies SHA-256 before extraction and rolls back automatically
when application health fails.

Use:

```bash
scripts/publish-backend-release.sh \
  coursistant-ielts-test \
  <artifact-bucket> \
  <release.tgz> \
  <release-id> \
  <sha256>
```

To roll back explicitly:

```bash
scripts/rollback-backend.sh coursistant-ielts-test
```

## Infrastructure rollback

Terraform source is the infrastructure authority. Revert the relevant Git
commit, review the resulting plan, then apply through the protected workflow.
Do not use `terraform destroy` as a rollback mechanism. Buckets and KMS keys
have deletion protections/recovery windows and are intentionally not ephemeral.

## Recorded test-environment exceptions

- S3 cross-region replication is disabled to keep student/test data within the
  approved Tokyo boundary. A second-region copy requires a separate compliance,
  retention, and cost decision.
- The provider-neutral Secrets Manager containers do not attach a generic
  automatic-rotation Lambda. Backend and AI credentials rotate through their
  owning provider workflows; record dates and evidence in the operational
  handoff.
