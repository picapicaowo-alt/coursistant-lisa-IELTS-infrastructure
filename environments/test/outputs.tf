output "application_url" {
  description = "HTTPS endpoint for the test environment."
  value       = module.compute.application_url
}

output "alb_dns_name" {
  description = "ALB DNS target to configure as a CNAME when DNS is external."
  value       = module.compute.alb_dns_name
}

output "uploads_bucket" {
  description = "Private S3 bucket used by backend application objects."
  value       = module.storage.uploads_bucket_id
}

output "artifacts_bucket" {
  description = "Private S3 bucket used by immutable release artifacts."
  value       = module.storage.artifacts_bucket_id
}

output "audit_bucket" {
  description = "Private S3 bucket used by ALB, S3, and CloudTrail audit logs."
  value       = module.storage.audit_bucket_id
}

output "backend_runtime_secret_arn" {
  description = "Secrets Manager container for backend runtime settings."
  value       = aws_secretsmanager_secret.backend_runtime.arn
}

output "ai_provider_secret_arn" {
  description = "Secrets Manager container for approved AI provider settings."
  value       = aws_secretsmanager_secret.ai_provider.arn
}

output "application_instance_role_arn" {
  description = "Least-privilege IAM role assumed by application instances."
  value       = module.compute.instance_role_arn
}

output "alarm_topic_arn" {
  description = "SNS topic used for operational alarms."
  value       = module.observability.alarm_topic_arn
}
