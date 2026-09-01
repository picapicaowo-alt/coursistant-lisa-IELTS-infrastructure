output "application_url" {
  description = "HTTPS URL for the test environment."
  value       = "https://${var.domain_name}"
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix used by CloudWatch metrics."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "Target-group ARN suffix used by CloudWatch metrics."
  value       = aws_lb_target_group.application.arn_suffix
}

output "autoscaling_group_name" {
  description = "Application Auto Scaling Group name."
  value       = aws_autoscaling_group.application.name
}

output "instance_role_arn" {
  description = "Least-privilege role assumed by application instances."
  value       = aws_iam_role.application.arn
}

output "application_security_group_id" {
  description = "Private application security-group ID."
  value       = aws_security_group.application.id
}

output "alb_security_group_id" {
  description = "Public ALB security-group ID."
  value       = aws_security_group.alb.id
}
