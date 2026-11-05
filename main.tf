data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

resource "aws_codebuild_source_credential" "this" {
  count = var.create_source_credential ? 1 : 0

  server_type = "GITHUB"
  auth_type   = var.credential_type
  token       = var.credential_arn
}

resource "aws_codebuild_project" "this" {
  name                   = var.name
  description            = "GitHub Actions runner for ${var.github_repository_url}"
  service_role           = aws_iam_role.this.arn
  build_timeout          = var.build_timeout
  concurrent_build_limit = var.concurrent_build_limit

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = var.compute_type
    image                       = var.image
    type                        = var.environment_type
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type     = "GITHUB"
    location = var.github_repository_url

    auth {
      type     = var.credential_type
      resource = var.credential_arn
    }
  }

  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = var.subnet_ids
    security_group_ids = [aws_security_group.this.id]
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.this.name
    }
  }

  tags = var.tags

  # The role policy must exist before CodeBuild checks the VPC and the credential.
  depends_on = [aws_iam_role_policy.this, aws_codebuild_source_credential.this]
}

# A repository webhook only receives events from that repository, so other repos can't queue jobs here.
resource "aws_codebuild_webhook" "this" {
  project_name = aws_codebuild_project.this.name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "WORKFLOW_JOB_QUEUED"
    }
  }
}
