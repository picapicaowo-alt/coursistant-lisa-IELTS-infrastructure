# Infrastructure Repository Rules

This repository owns only the AWS infrastructure and operational handoff for
the Coursistant IELTS testing environment.

- Never commit credentials, API keys, Terraform state, backend configuration,
  account IDs, private DNS values, or generated secret payloads.
- Infrastructure changes are made through Terraform. Console changes are for
  emergency recovery only and must be reconciled back into code.
- `test` is the only environment currently authorized. Do not create or mutate
  production resources from this repository.
- OpenAI is approved for the current closed test. Preserve the approval record,
  server-side credential boundary, usage limits, and tested `disabled` kill
  switch; re-review provider terms before expanding the test scope.
- S3 buckets remain private. Browser access must use authenticated backend
  authorization and short-lived presigned URLs.
- Use GitHub OIDC and AWS IAM roles. Do not create long-lived CI access keys.
- Keep releases immutable and retain `current` and `previous` for rollback.
- Do not invent backend API fields or application secrets. The backend team
  owns application behavior and maps the documented runtime contract.
