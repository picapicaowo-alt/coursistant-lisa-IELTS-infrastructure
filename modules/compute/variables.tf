variable "name_prefix" {
  description = "Prefix applied to compute resource names."
  type        = string
}

variable "aws_region" {
  description = "AWS region used by bootstrap and release scripts."
  type        = string
}

variable "vpc_id" {
  description = "VPC containing the ALB and application instances."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the internet-facing ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the application Auto Scaling Group."
  type        = list(string)
}

variable "domain_name" {
  description = "Fully qualified test hostname routed to the ALB."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 public hosted zone ID containing domain_name."
  type        = string
}

variable "allowed_ingress_ipv4_cidrs" {
  description = "IPv4 CIDRs allowed to reach public HTTP/HTTPS listeners."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ami_id" {
  description = "Optional x86_64 Amazon Linux 2023 AMI override."
  type        = string
  default     = null
  nullable    = true
}

variable "instance_type" {
  description = "EC2 instance type for the initial application server."
  type        = string
  default     = "m7i.xlarge"
}

variable "root_volume_size_gib" {
  description = "Encrypted gp3 root volume size in GiB."
  type        = number
  default     = 100
}

variable "desired_capacity" {
  description = "Desired number of application instances."
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum number of application instances."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of application instances."
  type        = number
  default     = 2
}

variable "uploads_bucket_id" {
  description = "Private upload bucket name exposed to the backend runtime."
  type        = string
}

variable "uploads_bucket_arn" {
  description = "Private upload bucket ARN used in the instance policy."
  type        = string
}

variable "artifacts_bucket_id" {
  description = "Immutable release artifact bucket name."
  type        = string
}

variable "artifacts_bucket_arn" {
  description = "Immutable release artifact bucket ARN."
  type        = string
}

variable "audit_bucket_id" {
  description = "Bucket receiving ALB access logs."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key used by EBS, S3, and Secrets Manager."
  type        = string
}

variable "secret_arns" {
  description = "Secrets Manager containers the application instance may read."
  type        = list(string)
}

variable "ai_provider_mode" {
  description = "Provider-neutral AI mode supplied as a non-secret runtime value."
  type        = string
}

variable "lms_api_port" {
  description = "Loopback port for the LMS/advising backend."
  type        = number
  default     = 8083
}

variable "ai_agent_port" {
  description = "Loopback port for the AI-agent backend."
  type        = number
  default     = 8090
}

variable "study_support_port" {
  description = "Loopback port for the Study Support backend."
  type        = number
  default     = 8091
}

variable "nginx_log_group_name" {
  description = "Pre-created CloudWatch log group for Nginx logs."
  type        = string
}

variable "application_log_group_name" {
  description = "Pre-created CloudWatch log group for application logs."
  type        = string
}

variable "backend_health_metric_namespace" {
  description = "CloudWatch namespace for continuous backend health metrics."
  type        = string
}

variable "backend_health_metric_environment" {
  description = "Environment dimension attached to backend health metrics."
  type        = string
}

variable "enable_waf" {
  description = "Associate AWS WAF managed rules and rate limiting with the ALB."
  type        = bool
  default     = true
}

variable "waf_rate_limit_per_five_minutes" {
  description = "Maximum requests per source IP in a five-minute WAF window."
  type        = number
  default     = 2000
}

variable "tags" {
  description = "Additional tags applied to compute resources."
  type        = map(string)
  default     = {}
}
