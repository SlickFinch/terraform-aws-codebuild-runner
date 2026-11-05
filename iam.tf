locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region

  credential_statement = var.credential_type == "SECRETS_MANAGER" ? {
    Sid      = "ReadGitHubToken"
    Effect   = "Allow"
    Action   = ["secretsmanager:GetSecretValue"]
    Resource = [var.credential_arn]
    } : {
    Sid      = "UseGitHubConnection"
    Effect   = "Allow"
    Action   = ["codeconnections:GetConnection", "codeconnections:GetConnectionToken"]
    Resource = [var.credential_arn]
  }
}

resource "aws_iam_role" "this" {
  name        = "${var.name}-codebuild"
  description = "Service role for the ${var.name} CodeBuild runner."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = { StringEquals = { "aws:SourceAccount" = local.account_id } }
    }]
  })

  tags = var.tags
}

# Workflow jobs get AWS access through GitHub OIDC, so this role only runs the build itself.
resource "aws_iam_role_policy" "this" {
  name = "runner"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "WriteLogs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = ["${aws_cloudwatch_log_group.this.arn}:*"]
      },
      {
        Sid    = "ManageNetworkInterfaces"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
        ]
        Resource = ["*"]
      },
      {
        Sid      = "AttachNetworkInterfaces"
        Effect   = "Allow"
        Action   = ["ec2:CreateNetworkInterfacePermission"]
        Resource = ["arn:${local.partition}:ec2:${local.region}:${local.account_id}:network-interface/*"]
        Condition = {
          StringEquals = {
            "ec2:Subnet"            = [for s in var.subnet_ids : "arn:${local.partition}:ec2:${local.region}:${local.account_id}:subnet/${s}"]
            "ec2:AuthorizedService" = "codebuild.amazonaws.com"
          }
        }
      },
      local.credential_statement,
    ]
  })
}
