variable "name_prefix" {
  description = "Prefix applied to storage resource names."
  type        = string
}

variable "account_id" {
  description = "AWS account ID used to make bucket names stable and unique."
  type        = string
}

variable "aws_region" {
  description = "AWS region used to scope audit service policies."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key used for S3 default encryption."
  type        = string
}

variable "cloudtrail_name" {
  description = "CloudTrail name allowed to write to the audit bucket."
  type        = string
}

variable "cors_allowed_origins" {
  description = "Explicit browser origins allowed for presigned upload/download requests."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for origin in var.cors_allowed_origins : origin != "*"])
    error_message = "Wildcard S3 CORS origins are not allowed."
  }
}

variable "uploads_noncurrent_expiration_days" {
  description = "Days to retain old upload object versions."
  type        = number
  default     = 30
}

variable "artifacts_noncurrent_expiration_days" {
  description = "Days to retain old deployment artifact versions."
  type        = number
  default     = 30
}

variable "audit_expiration_days" {
  description = "Days to retain audit objects for the test environment."
  type        = number
  default     = 90
}

variable "tags" {
  description = "Additional tags applied to storage resources."
  type        = map(string)
  default     = {}
}
