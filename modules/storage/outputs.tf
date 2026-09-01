output "uploads_bucket_id" {
  description = "Private application upload bucket name."
  value       = aws_s3_bucket.uploads.id
}

output "uploads_bucket_arn" {
  description = "Private application upload bucket ARN."
  value       = aws_s3_bucket.uploads.arn
}

output "artifacts_bucket_id" {
  description = "Immutable release artifact bucket name."
  value       = aws_s3_bucket.artifacts.id
}

output "artifacts_bucket_arn" {
  description = "Immutable release artifact bucket ARN."
  value       = aws_s3_bucket.artifacts.arn
}

output "audit_bucket_id" {
  description = "Audit log bucket name."
  value       = aws_s3_bucket.audit.id
}

output "audit_bucket_arn" {
  description = "Audit log bucket ARN."
  value       = aws_s3_bucket.audit.arn
}
