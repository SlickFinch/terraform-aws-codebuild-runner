variable "name" {
  description = "CodeBuild project name. Jobs pick the runner with the label codebuild-<name>-<run id>-<run attempt>."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]{1,50}$", var.name))
    error_message = "name must be 2 to 51 letters, digits, hyphens or underscores, so the role name <name>-codebuild fits IAM limits."
  }
}

variable "github_repository_url" {
  description = "HTTPS clone URL of the one repository whose workflow jobs may run here, for example https://github.com/acme/infra.git."
  type        = string

  validation {
    condition     = can(regex("^https://github\\.com/[^/]+/[^/]+\\.git$", var.github_repository_url))
    error_message = "github_repository_url must look like https://github.com/<owner>/<repo>.git."
  }
}

variable "credential_type" {
  description = "How CodeBuild authenticates to GitHub: SECRETS_MANAGER (a secret that holds a personal access token) or CODECONNECTIONS (the AWS Connector for GitHub app)."
  type        = string
  default     = "SECRETS_MANAGER"

  validation {
    condition     = contains(["SECRETS_MANAGER", "CODECONNECTIONS"], var.credential_type)
    error_message = "credential_type must be SECRETS_MANAGER or CODECONNECTIONS."
  }
}

variable "credential_arn" {
  description = "ARN of the Secrets Manager secret or the CodeConnections connection that credential_type names."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:(secretsmanager|codeconnections|codestar-connections):", var.credential_arn))
    error_message = "credential_arn must be a Secrets Manager secret ARN or a CodeConnections connection ARN."
  }
}

variable "create_source_credential" {
  description = "Create the account-wide GitHub source credential. CodeBuild keeps one per account and Region, so set false if something else manages it. The project authenticates on its own either way."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC the builds run in."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets the builds run in. They need a route to the internet (NAT) to reach GitHub."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must name at least one subnet."
  }
}

variable "egress_cidr_blocks" {
  description = "IPv4 CIDRs the builds may send traffic to, on any port."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "compute_type" {
  description = "CodeBuild compute type."
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "image" {
  description = "Build image."
  type        = string
  default     = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
}

variable "environment_type" {
  description = "CodeBuild environment type, for example LINUX_CONTAINER or ARM_CONTAINER."
  type        = string
  default     = "LINUX_CONTAINER"
}

variable "build_timeout" {
  description = "Minutes before CodeBuild stops a build (5 to 2160)."
  type        = number
  default     = 60
}

variable "concurrent_build_limit" {
  description = "Most builds that run at once. Null means the account limit."
  type        = number
  default     = null
}

variable "log_retention_in_days" {
  description = "Days CloudWatch Logs keeps build logs."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags for every taggable resource."
  type        = map(string)
  default     = {}
}
