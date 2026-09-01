output "aws_region" {
  description = "AWS region used by the test stack."
  value       = var.aws_region
}

output "terraform_state_bucket" {
  description = "Encrypted S3 bucket for Terraform remote state and lock files."
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_plan_role_arn" {
  description = "GitHub OIDC role for Terraform plans."
  value       = aws_iam_role.terraform_plan.arn
}

output "terraform_apply_role_arn" {
  description = "Protected GitHub OIDC role for Terraform applies."
  value       = aws_iam_role.terraform_apply.arn
}
