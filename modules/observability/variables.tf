variable "name_prefix" {
  description = "Prefix applied to monitoring resource names."
  type        = string
}

variable "aws_region" {
  description = "AWS region containing the monitored environment."
  type        = string
}

variable "account_id" {
  description = "AWS account ID used by CloudTrail."
  type        = string
}

variable "cloudtrail_name" {
  description = "Name of the test-environment CloudTrail."
  type        = string
}

variable "cloudtrail_kms_key_arn" {
  description = "Customer-managed KMS key used to encrypt CloudTrail log files."
  type        = string
}

variable "audit_bucket_id" {
  description = "S3 bucket receiving CloudTrail management events."
  type        = string
}

variable "autoscaling_group_name" {
  description = "Application Auto Scaling Group monitored for capacity."
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix used in CloudWatch dimensions."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ALB target-group ARN suffix used in CloudWatch dimensions."
  type        = string
}

variable "backend_health_metric_namespace" {
  description = "CloudWatch namespace containing the backend health metric."
  type        = string
}

variable "backend_health_metric_environment" {
  description = "Environment dimension attached to the backend health metric."
  type        = string
}

variable "alarm_email" {
  description = "Email address subscribed to alarms and the monthly budget."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", var.alarm_email))
    error_message = "alarm_email must be a valid email address."
  }
}

variable "monthly_budget_usd" {
  description = "Monthly test-environment budget in USD."
  type        = number
  default     = 400
}

variable "tags" {
  description = "Additional tags applied to monitoring resources."
  type        = map(string)
  default     = {}
}
