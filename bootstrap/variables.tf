variable "aws_region" {
  description = "AWS region that owns the Terraform state and OIDC roles."
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  description = "Stable project identifier used in resource names."
  type        = string
  default     = "coursistant-ielts"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "project must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "github_organization" {
  description = "GitHub organization or owner allowed to assume the OIDC roles."
  type        = string
  default     = "picapicaowo-alt"
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the OIDC roles."
  type        = string
  default     = "coursistant-lisa-IELTS-infrastructure"
}

variable "github_environment" {
  description = "Protected GitHub environment allowed to apply Terraform."
  type        = string
  default     = "test"
}

variable "state_bucket_prefix" {
  description = "Prefix for the globally unique Terraform state bucket."
  type        = string
  default     = "coursistant-ielts-terraform-state"
}

variable "existing_github_oidc_provider_arn" {
  description = "Existing GitHub Actions OIDC provider ARN to reuse; null creates one."
  type        = string
  default     = null
  nullable    = true
}
