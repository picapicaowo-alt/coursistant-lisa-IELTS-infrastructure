# One-time bootstrap runbook

The bootstrap stack creates the encrypted/versioned Terraform state bucket and
GitHub OIDC roles. It is the only step that requires a locally authenticated
AWS administrator.

## Prerequisites

- A dedicated or approved AWS account for the test environment.
- AWS CLI credentials obtained through the organization's normal SSO/role
  process; do not create a long-lived access key for this repository.
- Terraform 1.10 or newer.
- Permission to create S3, IAM roles/policies, and an IAM OIDC provider.

If the AWS account already has
`token.actions.githubusercontent.com` configured as an IAM OIDC provider, put
its ARN in `existing_github_oidc_provider_arn`; AWS permits only one provider
resource for the same URL in an account.

## Procedure

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan -out=bootstrap.tfplan
terraform apply bootstrap.tfplan
```

Record the outputs in GitHub repository variables:

- `AWS_REGION`
- `TF_STATE_BUCKET`
- `AWS_TERRAFORM_PLAN_ROLE_ARN`
- `AWS_TERRAFORM_APPLY_ROLE_ARN`

Create a protected GitHub environment named `test`; require reviewer approval
for deployments. Store the non-secret environment values as repository or
environment variables. Store the test Terraform input JSON as the protected
environment secret `TFVARS_JSON`; it must not contain application/API secrets.

After the first apply, migrate bootstrap state into the created S3 state bucket
or store it in the organization's approved state system. Do not commit local
state.
