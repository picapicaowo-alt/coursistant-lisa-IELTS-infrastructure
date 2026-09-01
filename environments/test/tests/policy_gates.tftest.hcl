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
  target = module.compute.aws_acm_certificate.this
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

run "safe_mainland_defaults" {
  command = plan

  variables {
    domain_name    = "test.example.com"
    hosted_zone_id = "Z0000000000000000000"
    alarm_email    = "ops@example.com"
  }

  assert {
    condition     = var.ai_provider_mode == "disabled"
    error_message = "The test environment must default to AI disabled."
  }

  assert {
    condition     = var.mainland_end_users
    error_message = "The safe test default must assume mainland end users."
  }
}

run "reject_openai_for_mainland_users" {
  command = plan

  variables {
    domain_name                          = "test.example.com"
    hosted_zone_id                       = "Z0000000000000000000"
    alarm_email                          = "ops@example.com"
    ai_provider_mode                     = "openai"
    mainland_end_users                   = true
    openai_supported_end_users_confirmed = true
  }

  expect_failures = [check.openai_geography_gate]
}

run "allow_openai_only_after_supported_user_confirmation" {
  command = plan

  variables {
    domain_name                          = "test.example.com"
    hosted_zone_id                       = "Z0000000000000000000"
    alarm_email                          = "ops@example.com"
    ai_provider_mode                     = "openai"
    mainland_end_users                   = false
    openai_supported_end_users_confirmed = true
  }

  assert {
    condition     = var.ai_provider_mode == "openai" && !var.mainland_end_users && var.openai_supported_end_users_confirmed
    error_message = "OpenAI must require supported-user confirmation and no mainland end users."
  }
}
