# Runs without AWS credentials: `tofu test` (or `terraform test`).

mock_provider "aws" {
  override_data {
    target = data.aws_caller_identity.current
    values = { account_id = "111111111111" }
  }
  override_data {
    target = data.aws_partition.current
    values = { partition = "aws" }
  }
  override_data {
    target = data.aws_region.current
    values = { region = "us-west-2" }
  }
  override_resource {
    target = aws_cloudwatch_log_group.this
    values = { arn = "arn:aws:logs:us-west-2:111111111111:log-group:/aws/codebuild/example-runner" }
  }
  override_resource {
    target = aws_iam_role.this
    values = { arn = "arn:aws:iam::111111111111:role/example-runner-codebuild" }
  }
}

variables {
  name                  = "example-runner"
  github_repository_url = "https://github.com/example-org/example-repo.git"
  credential_arn        = "arn:aws:secretsmanager:us-west-2:111111111111:secret:example-pat-AbCdEf"
  vpc_id                = "vpc-0123456789abcdef0"
  subnet_ids            = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
}

run "webhook_filters" {
  assert {
    condition     = length(aws_codebuild_webhook.this.filter_group) == 1
    error_message = "The webhook must have exactly one filter group."
  }
  assert {
    condition     = [for g in aws_codebuild_webhook.this.filter_group : [for f in g.filter : "${f.type}=${f.pattern}"]][0] == ["EVENT=WORKFLOW_JOB_QUEUED"]
    error_message = "The filter group must only match WORKFLOW_JOB_QUEUED events."
  }
  assert {
    condition     = aws_codebuild_webhook.this.build_type == "BUILD"
    error_message = "The webhook must start BUILD builds."
  }
}

run "webhook_is_repo_scoped" {
  assert {
    condition     = length(aws_codebuild_webhook.this.scope_configuration) == 0
    error_message = "The webhook must be scoped to the project's repository, not an organization or global scope."
  }
  assert {
    condition     = aws_codebuild_project.this.source[0].location == var.github_repository_url
    error_message = "The project source must be the given repository."
  }
}

run "source_auth" {
  assert {
    condition     = aws_codebuild_project.this.source[0].auth[0].type == "SECRETS_MANAGER"
    error_message = "The project must authenticate with the Secrets Manager secret by default."
  }
  assert {
    condition     = aws_codebuild_project.this.source[0].auth[0].resource == var.credential_arn
    error_message = "The project auth resource must be credential_arn."
  }
  assert {
    condition     = aws_codebuild_source_credential.this[0].auth_type == "SECRETS_MANAGER" && aws_codebuild_source_credential.this[0].token == var.credential_arn && aws_codebuild_source_credential.this[0].server_type == "GITHUB"
    error_message = "The source credential must point at the secret ARN, never a raw token."
  }
}

run "codeconnections_switch" {
  variables {
    credential_type = "CODECONNECTIONS"
    credential_arn  = "arn:aws:codeconnections:us-west-2:111111111111:connection/0123abcd-0123-abcd-0123-0123456789ab"
  }
  assert {
    condition     = aws_codebuild_source_credential.this[0].auth_type == "CODECONNECTIONS"
    error_message = "The source credential must switch to CODECONNECTIONS."
  }
  assert {
    condition     = strcontains(aws_iam_role_policy.this.policy, "codeconnections:GetConnectionToken") && !strcontains(aws_iam_role_policy.this.policy, "secretsmanager:")
    error_message = "With CODECONNECTIONS the role reads the connection and nothing in Secrets Manager."
  }
}

run "no_source_credential" {
  variables {
    create_source_credential = false
  }
  assert {
    condition     = length(aws_codebuild_source_credential.this) == 0
    error_message = "create_source_credential = false must skip the account-wide source credential."
  }
  assert {
    condition     = aws_codebuild_project.this.source[0].auth[0].resource == var.credential_arn
    error_message = "The project must still authenticate on its own."
  }
}

run "role_is_narrow" {
  assert {
    condition = alltrue(flatten([
      for s in jsondecode(aws_iam_role_policy.this.policy).Statement : [
        for a in flatten([s.Action]) : !startswith(a, "sts:") && !startswith(a, "iam:") && a != "*" && !endswith(a, ":*")
      ]
    ]))
    error_message = "The role policy must not grant sts, iam or wildcard actions."
  }
  assert {
    condition = alltrue([
      for s in jsondecode(aws_iam_role_policy.this.policy).Statement : flatten([s.Resource]) == [var.credential_arn]
      if contains(flatten([s.Action]), "secretsmanager:GetSecretValue")
    ])
    error_message = "secretsmanager:GetSecretValue must name only credential_arn."
  }
  assert {
    condition     = aws_iam_role.this.name == "example-runner-codebuild"
    error_message = "The role name must be <name>-codebuild so callers can build its ARN before apply."
  }
}

run "sg_egress_only" {
  assert {
    condition     = length(aws_security_group.this.ingress) == 0
    error_message = "The security group must have no ingress rules."
  }
  assert {
    condition     = toset([for r in aws_vpc_security_group_egress_rule.this : r.cidr_ipv4]) == toset(["0.0.0.0/0"])
    error_message = "Egress must default to 0.0.0.0/0 and follow egress_cidr_blocks."
  }
}

run "logs" {
  variables {
    log_retention_in_days = 14
  }
  assert {
    condition     = aws_cloudwatch_log_group.this.retention_in_days == 14
    error_message = "The log group retention must follow log_retention_in_days."
  }
  assert {
    condition     = aws_codebuild_project.this.logs_config[0].cloudwatch_logs[0].group_name == aws_cloudwatch_log_group.this.name
    error_message = "The project must log to the module's log group."
  }
}

run "label" {
  assert {
    condition     = output.runner_label_prefix == "codebuild-example-runner"
    error_message = "runner_label_prefix must be codebuild-<name>."
  }
}

run "bad_url" {
  command = plan
  variables {
    github_repository_url = "git@github.com:a/b.git"
  }
  expect_failures = [var.github_repository_url]
}
