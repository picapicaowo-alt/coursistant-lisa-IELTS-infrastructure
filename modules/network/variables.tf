variable "name_prefix" {
  description = "Prefix applied to network resource names."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the isolated environment VPC."
  type        = string
}

variable "availability_zones" {
  description = "Availability Zones used by the environment."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two Availability Zones are required."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDRs for internet-facing load-balancer subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private application subnets."
  type        = list(string)
}

variable "high_availability_nat" {
  description = "Create one NAT Gateway per AZ instead of a single test NAT Gateway."
  type        = bool
  default     = false
}

variable "flow_log_group_arn" {
  description = "Encrypted CloudWatch log-group ARN receiving VPC Flow Logs."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to all network resources."
  type        = map(string)
  default     = {}
}
