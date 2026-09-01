variable "aws_region" {
  description = "AWS region for the isolated test environment."
  type        = string
  default     = "ap-northeast-1"

  validation {
    condition     = var.aws_region == "ap-northeast-1"
    error_message = "This environment is authorized only for AWS Tokyo (ap-northeast-1)."
  }
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

variable "environment" {
  description = "Authorized deployment environment."
  type        = string
  default     = "test"

  validation {
    condition     = var.environment == "test"
    error_message = "Only the test environment is authorized in this repository."
  }
}

variable "owner" {
  description = "Team responsible for the environment."
  type        = string
  default     = "coursistant"
}

variable "domain_name" {
  description = "Fully qualified hostname for the Tokyo test environment."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$", var.domain_name))
    error_message = "domain_name must be a valid fully qualified domain name."
  }
}

variable "hosted_zone_id" {
  description = "Route 53 public hosted-zone ID containing domain_name."
  type        = string
}

variable "alarm_email" {
  description = "Email recipient for CloudWatch/SNS and AWS Budget alerts."
  type        = string
  sensitive   = true
}

variable "vpc_cidr" {
  description = "CIDR block for the isolated test VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Two public subnet CIDRs for the ALB."
  type        = list(string)
  default     = ["10.42.0.0/24", "10.42.1.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly two public subnet CIDRs are required."
  }
}

variable "private_subnet_cidrs" {
  description = "Two private subnet CIDRs for application instances."
  type        = list(string)
  default     = ["10.42.10.0/24", "10.42.11.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Exactly two private subnet CIDRs are required."
  }
}

variable "high_availability_nat" {
  description = "Create one NAT Gateway per AZ instead of the cost-conscious single test NAT."
  type        = bool
  default     = false
}

variable "allowed_ingress_ipv4_cidrs" {
  description = "IPv4 CIDRs allowed to reach the public ALB. Use known test ranges where possible."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "Initial x86_64 server size; m7i.xlarge provides 4 vCPU and 16 GiB."
  type        = string
  default     = "m7i.xlarge"
}

variable "ami_id" {
  description = "Optional approved x86_64 Amazon Linux 2023 AMI override."
  type        = string
  default     = null
  nullable    = true
}

variable "root_volume_size_gib" {
  description = "Encrypted gp3 root-volume size in GiB."
  type        = number
  default     = 100

  validation {
    condition     = var.root_volume_size_gib >= 30 && var.root_volume_size_gib <= 1024
    error_message = "root_volume_size_gib must be between 30 and 1024 GiB."
  }
}

variable "desired_capacity" {
  description = "Desired application instance count."
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum application instance count."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum application instance count."
  type        = number
  default     = 2
}

variable "lms_api_port" {
  description = "Loopback port for /api."
  type        = number
  default     = 8083
}

variable "ai_agent_port" {
  description = "Loopback port for /ai-agent."
  type        = number
  default     = 8090
}

variable "study_support_port" {
  description = "Loopback port for /study-support."
  type        = number
  default     = 8091
}

variable "cors_allowed_origins" {
  description = "Explicit browser origins allowed to use presigned S3 requests."
  type        = list(string)
  default     = []
}

variable "waf_rate_limit_per_five_minutes" {
  description = "Maximum WAF requests per source IP in five minutes."
  type        = number
  default     = 2000
}

variable "monthly_budget_usd" {
  description = "Monthly AWS budget for the test environment."
  type        = number
  default     = 400
}

variable "ai_provider_mode" {
  description = "AI provider mode. Keep disabled until the documented gate is approved."
  type        = string
  default     = "disabled"

  validation {
    condition     = contains(["disabled", "mainland-approved", "openai"], var.ai_provider_mode)
    error_message = "ai_provider_mode must be disabled, mainland-approved, or openai."
  }
}

variable "mainland_end_users" {
  description = "Whether any test end users are located in mainland China."
  type        = bool
  default     = true
}

variable "openai_supported_end_users_confirmed" {
  description = "Recorded confirmation that every OpenAI end user is in a supported country."
  type        = bool
  default     = false
}

variable "uploads_noncurrent_expiration_days" {
  description = "Days to keep prior upload object versions."
  type        = number
  default     = 30
}

variable "artifacts_noncurrent_expiration_days" {
  description = "Days to keep prior artifact object versions."
  type        = number
  default     = 30
}

variable "audit_expiration_days" {
  description = "Days to retain test-environment audit objects."
  type        = number
  default     = 90
}
