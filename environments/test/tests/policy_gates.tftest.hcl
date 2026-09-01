mock_provider "aws" {}

override_data {
  target = data.aws_caller_identity.current
  values = {
    account_id = "123456789012"
    arn        = "arn:aws:iam::123456789012:role/terraform-test"
    id         = "123456789012"
    user_id    = "terraform-test"
  }
}

override_data {
  target = data.aws_partition.current
  values = {
    partition  = "aws"
    dns_suffix = "amazonaws.com"
  }
}

override_data {
  target = data.aws_availability_zones.available
  values = {
    names = ["ap-northeast-1a", "ap-northeast-1c"]
  }
}

override_data {
  target = module.network.data.aws_region.current
  values = {
    region = "ap-northeast-1"
  }
}

override_data {
  target = module.compute.data.aws_vpc.selected
  values = {
    cidr_block = "10.42.0.0/16"
  }
}

override_data {
  target = module.compute.data.aws_ami.amazon_linux_2023[0]
  values = {
    id = "ami-0123456789abcdef0"
  }
}

override_resource {
  target = module.compute.aws_acm_certificate.this[0]
  values = {
    arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
    domain_validation_options = [
      {
        domain_name           = "test.example.com"
        resource_record_name  = "_validation.test.example.com"
        resource_record_type  = "CNAME"
        resource_record_value = "_validation.acm-validations.aws"
      }
    ]
  }
}

override_data {
  target = data.aws_iam_policy_document.environment_kms
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
}

override_data {
  target = module.storage.data.aws_iam_policy_document.uploads
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
}

override_data {
  target = module.storage.data.aws_iam_policy_document.artifacts
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
}

override_data {
  target = module.storage.data.aws_iam_policy_document.audit
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
}

override_data {
  target = module.compute.data.aws_iam_policy_document.ec2_assume_role
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
}

override_data {
  target = module.compute.data.aws_iam_policy_document.application
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
}

override_data {
  target = module.network.data.aws_iam_policy_document.flow_logs_assume_role
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
}

override_data {
  target = module.network.data.aws_iam_policy_document.flow_logs
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
}

override_data {
  target = module.observability.data.aws_iam_policy_document.cloudtrail_assume_role
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
}

override_data {
  target = module.observability.data.aws_iam_policy_document.cloudtrail_logs
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
}

run "approved_openai_default" {
  command = plan

  variables {
    domain_name    = "test.example.com"
    hosted_zone_id = "Z0000000000000000000"
    alarm_email    = "ops@example.com"
  }

  assert {
    condition     = var.ai_provider_mode == "openai"
    error_message = "The approved closed test must default to OpenAI."
  }
}

run "allow_explicit_ai_disable_kill_switch" {
  command = plan

  variables {
    domain_name      = "test.example.com"
    hosted_zone_id   = "Z0000000000000000000"
    alarm_email      = "ops@example.com"
    ai_provider_mode = "disabled"
  }

  assert {
    condition     = var.ai_provider_mode == "disabled"
    error_message = "Operators must retain an explicit AI kill-switch mode."
  }
}

run "allow_approved_openai_test" {
  command = plan

  variables {
    domain_name      = "test.example.com"
    hosted_zone_id   = "Z0000000000000000000"
    alarm_email      = "ops@example.com"
    ai_provider_mode = "openai"
  }

  assert {
    condition     = var.ai_provider_mode == "openai"
    error_message = "The approved OpenAI test mode must be deployable."
  }
}

run "allow_external_dns_with_issued_tokyo_certificate" {
  command = plan

  variables {
    domain_name     = "test.example.com"
    hosted_zone_id  = null
    certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
    alarm_email     = "ops@example.com"
  }

  assert {
    condition     = var.hosted_zone_id == null && var.certificate_arn != null
    error_message = "External DNS mode must accept an issued Tokyo ACM certificate."
  }
}
