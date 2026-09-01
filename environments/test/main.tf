data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix        = "${var.project}-${var.environment}"
  cloudtrail_name    = "${local.name_prefix}-management"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  common_tags = {
    ManagedBy   = "Terraform"
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    Repository  = "picapicaowo-alt/coursistant-lisa-IELTS-infrastructure"
  }
  nginx_log_group_name       = "/${var.project}/${var.environment}/nginx"
  application_log_group_name = "/${var.project}/${var.environment}/application"
}

check "openai_geography_gate" {
  assert {
    condition = var.ai_provider_mode != "openai" || (
      !var.mainland_end_users && var.openai_supported_end_users_confirmed
    )
    error_message = "OpenAI cannot be enabled for mainland-China end users and requires explicit supported-user confirmation."
  }
}

check "capacity_bounds" {
  assert {
    condition     = var.min_size <= var.desired_capacity && var.desired_capacity <= var.max_size
    error_message = "Capacity must satisfy min_size <= desired_capacity <= max_size."
  }
}

data "aws_iam_policy_document" "environment_kms" {
  #checkov:skip=CKV_AWS_109:The account-root KMS statement is the AWS default delegation pattern; IAM policies remain the authorization boundary.
  #checkov:skip=CKV_AWS_111:The account-root KMS statement must permit key administration so the account can delegate scoped use through IAM.
  #checkov:skip=CKV_AWS_356:KMS key policies require Resource "*" because the policy is already attached to exactly one key.
  statement {
    sid    = "EnableAccountIamPolicies"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudWatchLogsEncryption"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
    ]
    resources = ["*"]

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [
        "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/${var.project}/${var.environment}/*",
        "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:aws-waf-logs-${local.name_prefix}",
      ]
    }
  }

  statement {
    sid    = "AllowCloudTrailEncryption"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${local.cloudtrail_name}"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
    }
  }
}

resource "aws_kms_key" "environment" {
  description             = "${local.name_prefix} data, secret, and volume encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.environment_kms.json
  tags                    = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "environment" {
  name          = "alias/${local.name_prefix}"
  target_key_id = aws_kms_key.environment.key_id
}

resource "aws_secretsmanager_secret" "backend_runtime" {
  #checkov:skip=CKV2_AWS_57:This provider-neutral secret has no rotation Lambda; the backend owner rotates its independent credentials under the runbook.
  name                    = "${local.name_prefix}/backend/runtime"
  description             = "Backend runtime settings; values are populated out of band."
  kms_key_id              = aws_kms_key.environment.arn
  recovery_window_in_days = 30
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret" "ai_provider" {
  #checkov:skip=CKV2_AWS_57:Provider credentials have provider-owned rotation APIs; no generic rotation Lambda can safely rotate every supported provider.
  name                    = "${local.name_prefix}/ai/provider"
  description             = "Approved AI provider settings; keep without a value while disabled."
  kms_key_id              = aws_kms_key.environment.arn
  recovery_window_in_days = 30
  tags                    = local.common_tags
}

resource "aws_cloudwatch_log_group" "nginx" {
  name              = local.nginx_log_group_name
  retention_in_days = 365
  kms_key_id        = aws_kms_key.environment.arn
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "application" {
  name              = local.application_log_group_name
  retention_in_days = 365
  kms_key_id        = aws_kms_key.environment.arn
  tags              = local.common_tags
}

module "network" {
  source = "../../modules/network"

  name_prefix           = local.name_prefix
  vpc_cidr              = var.vpc_cidr
  availability_zones    = local.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  high_availability_nat = var.high_availability_nat
  tags                  = local.common_tags
}

module "storage" {
  source = "../../modules/storage"

  name_prefix                          = local.name_prefix
  account_id                           = data.aws_caller_identity.current.account_id
  aws_region                           = var.aws_region
  kms_key_arn                          = aws_kms_key.environment.arn
  cloudtrail_name                      = local.cloudtrail_name
  cors_allowed_origins                 = var.cors_allowed_origins
  uploads_noncurrent_expiration_days   = var.uploads_noncurrent_expiration_days
  artifacts_noncurrent_expiration_days = var.artifacts_noncurrent_expiration_days
  audit_expiration_days                = var.audit_expiration_days
  tags                                 = local.common_tags
}

module "compute" {
  source = "../../modules/compute"

  name_prefix                       = local.name_prefix
  aws_region                        = var.aws_region
  vpc_id                            = module.network.vpc_id
  public_subnet_ids                 = module.network.public_subnet_ids
  private_subnet_ids                = module.network.private_subnet_ids
  domain_name                       = var.domain_name
  hosted_zone_id                    = var.hosted_zone_id
  allowed_ingress_ipv4_cidrs        = var.allowed_ingress_ipv4_cidrs
  ami_id                            = var.ami_id
  instance_type                     = var.instance_type
  root_volume_size_gib              = var.root_volume_size_gib
  desired_capacity                  = var.desired_capacity
  min_size                          = var.min_size
  max_size                          = var.max_size
  uploads_bucket_id                 = module.storage.uploads_bucket_id
  uploads_bucket_arn                = module.storage.uploads_bucket_arn
  artifacts_bucket_id               = module.storage.artifacts_bucket_id
  artifacts_bucket_arn              = module.storage.artifacts_bucket_arn
  audit_bucket_id                   = module.storage.audit_bucket_id
  kms_key_arn                       = aws_kms_key.environment.arn
  secret_arns                       = [aws_secretsmanager_secret.backend_runtime.arn, aws_secretsmanager_secret.ai_provider.arn]
  ai_provider_mode                  = var.ai_provider_mode
  lms_api_port                      = var.lms_api_port
  ai_agent_port                     = var.ai_agent_port
  study_support_port                = var.study_support_port
  nginx_log_group_name              = local.nginx_log_group_name
  application_log_group_name        = local.application_log_group_name
  backend_health_metric_namespace   = "Coursistant/Backend"
  backend_health_metric_environment = var.environment
  enable_waf                        = var.enable_waf
  waf_rate_limit_per_five_minutes   = var.waf_rate_limit_per_five_minutes
  tags                              = local.common_tags

  depends_on = [
    aws_cloudwatch_log_group.application,
    aws_cloudwatch_log_group.nginx,
    module.storage,
  ]
}

module "observability" {
  source = "../../modules/observability"

  name_prefix                       = local.name_prefix
  aws_region                        = var.aws_region
  account_id                        = data.aws_caller_identity.current.account_id
  cloudtrail_name                   = local.cloudtrail_name
  cloudtrail_kms_key_arn            = aws_kms_key.environment.arn
  audit_bucket_id                   = module.storage.audit_bucket_id
  autoscaling_group_name            = module.compute.autoscaling_group_name
  alb_arn_suffix                    = module.compute.alb_arn_suffix
  target_group_arn_suffix           = module.compute.target_group_arn_suffix
  backend_health_metric_namespace   = "Coursistant/Backend"
  backend_health_metric_environment = var.environment
  alarm_email                       = var.alarm_email
  monthly_budget_usd                = var.monthly_budget_usd
  tags                              = local.common_tags

  depends_on = [module.storage, module.compute]
}
