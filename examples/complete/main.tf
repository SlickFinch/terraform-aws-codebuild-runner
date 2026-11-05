# A runner for one repository, in private subnets with NAT, reading a GitHub token from Secrets Manager.

provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.7"

  name               = "example-runner"
  cidr               = "10.20.0.0/16"
  azs                = ["us-west-2a", "us-west-2b"]
  private_subnets    = ["10.20.0.0/20", "10.20.16.0/20"]
  public_subnets     = ["10.20.240.0/24", "10.20.241.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
}

# The secret has no value here; put the token in by hand so it never enters state.
resource "aws_secretsmanager_secret" "github_token" {
  name = "example-runner-github-token"

  tags = {
    "codebuild:source:provider" = "github"
    "codebuild:source:type"     = "personal_access_token"
  }
}

module "runner" {
  source = "../.."

  name                  = "example-runner"
  github_repository_url = "https://github.com/acme/infra.git"
  credential_arn        = aws_secretsmanager_secret.github_token.arn

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

output "runs_on" {
  description = "Value for runs-on in the workflow."
  value       = "${module.runner.runner_label_prefix}-$${{ github.run_id }}-$${{ github.run_attempt }}"
}
