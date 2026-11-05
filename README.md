# terraform-aws-codebuild-runner

OpenTofu and Terraform module that creates an AWS CodeBuild-hosted GitHub Actions runner for one repository. Workflow jobs in that repository run in your VPC, so they can reach private endpoints such as a private EKS API.

## Usage

Pin the module to a release tag:

```hcl
module "runner" {
  source = "git::https://github.com/SlickFinch/terraform-aws-codebuild-runner.git?ref=v1.0.0"

  name                  = "acme-runner"
  github_repository_url = "https://github.com/acme/infra.git"
  credential_arn        = aws_secretsmanager_secret.github_token.arn

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}
```

In the workflow, use the label the module builds:

```yaml
runs-on: codebuild-acme-runner-${{ github.run_id }}-${{ github.run_attempt }}
```

See [examples/complete](examples/complete) for a VPC, the secret and the apply order.

## How it behaves

- **One repository.** The webhook belongs to the repository in `github_repository_url`, and its only filter is `WORKFLOW_JOB_QUEUED`. GitHub sends a repository webhook only that repository's events, so jobs from other repositories never start a build here.
- **Credentials.** With `credential_type = "SECRETS_MANAGER"`, `credential_arn` is a secret whose value is `{"ServerType":"GITHUB","AuthType":"PERSONAL_ACCESS_TOKEN","Token":"<token>"}`, tagged `codebuild:source:provider = github` and `codebuild:source:type = personal_access_token`. With `CODECONNECTIONS`, it is a connection ARN. Changing the type is a variable change. The module never sees the token.
- **Source credential.** CodeBuild keeps one GitHub source credential per account and Region. The module creates it by default. Set `create_source_credential = false` if something else manages it. The project also authenticates on its own.
- **Token scopes.** A classic token needs `repo`. A fine-grained token needs Contents (read), Commit statuses (read and write), Webhooks (read and write) and Administration (read and write) on the repository.
- **Service role.** It can write to its log group, manage the build's network interfaces in `subnet_ids`, and read the one credential. It has no `sts` or `iam` actions. Jobs get AWS access through GitHub OIDC.
- **Network.** The security group has no ingress rules. Egress follows `egress_cidr_blocks`, on every port unless `egress_tcp_ports` lists the TCP ports to allow (for example `[443]`). The subnets need NAT to reach GitHub.

## Apply order

The webhook needs a working credential when it is created. Create the secret, put the token in it, then apply the module.

## Testing

```bash
mise install
tofu test            # mocked provider, no AWS credentials needed
pre-commit run --all-files
```

## Versioning

Releases follow [semantic versioning](https://semver.org). Each release is a `vMAJOR.MINOR.PATCH` git tag with a GitHub release. [CHANGELOG.md](CHANGELOG.md) lists the changes in each release.

- **Patch:** bug fixes. No change to inputs, outputs or resources.
- **Minor:** new inputs or outputs with safe defaults.
- **Major:** anything that makes callers change code, raises a provider floor, or replaces resources.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_codebuild_project.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codebuild_source_credential.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_source_credential) | resource |
| [aws_codebuild_webhook.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_webhook) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_credential_arn"></a> [credential\_arn](#input\_credential\_arn) | ARN of the Secrets Manager secret or the CodeConnections connection that credential\_type names. | `string` | n/a | yes |
| <a name="input_github_repository_url"></a> [github\_repository\_url](#input\_github\_repository\_url) | HTTPS clone URL of the one repository whose workflow jobs may run here, for example https://github.com/acme/infra.git. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | CodeBuild project name. Jobs pick the runner with the label codebuild-<name>-<run id>-<run attempt>. | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Private subnets the builds run in. They need a route to the internet (NAT) to reach GitHub. | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC the builds run in. | `string` | n/a | yes |
| <a name="input_build_timeout"></a> [build\_timeout](#input\_build\_timeout) | Minutes before CodeBuild stops a build (5 to 2160). | `number` | `60` | no |
| <a name="input_compute_type"></a> [compute\_type](#input\_compute\_type) | CodeBuild compute type. | `string` | `"BUILD_GENERAL1_SMALL"` | no |
| <a name="input_concurrent_build_limit"></a> [concurrent\_build\_limit](#input\_concurrent\_build\_limit) | Most builds that run at once. Null means the account limit. | `number` | `null` | no |
| <a name="input_create_source_credential"></a> [create\_source\_credential](#input\_create\_source\_credential) | Create the account-wide GitHub source credential. CodeBuild keeps one per account and Region, so set false if something else manages it. The project authenticates on its own either way. | `bool` | `true` | no |
| <a name="input_credential_type"></a> [credential\_type](#input\_credential\_type) | How CodeBuild authenticates to GitHub: SECRETS\_MANAGER (a secret that holds a personal access token) or CODECONNECTIONS (the AWS Connector for GitHub app). | `string` | `"SECRETS_MANAGER"` | no |
| <a name="input_egress_cidr_blocks"></a> [egress\_cidr\_blocks](#input\_egress\_cidr\_blocks) | IPv4 CIDRs the builds may send traffic to, on any port. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_egress_tcp_ports"></a> [egress\_tcp\_ports](#input\_egress\_tcp\_ports) | TCP ports the builds may use toward egress\_cidr\_blocks. Null allows every protocol and port. | `list(number)` | `null` | no |
| <a name="input_environment_type"></a> [environment\_type](#input\_environment\_type) | CodeBuild environment type, for example LINUX\_CONTAINER or ARM\_CONTAINER. | `string` | `"LINUX_CONTAINER"` | no |
| <a name="input_image"></a> [image](#input\_image) | Build image. | `string` | `"aws/codebuild/amazonlinux-x86_64-standard:5.0"` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | Days CloudWatch Logs keeps build logs. | `number` | `30` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for every taggable resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_project_arn"></a> [project\_arn](#output\_project\_arn) | ARN of the CodeBuild project. |
| <a name="output_project_name"></a> [project\_name](#output\_project\_name) | Name of the CodeBuild project. |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the CodeBuild service role. |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the CodeBuild service role, always <name>-codebuild. |
| <a name="output_runner_label_prefix"></a> [runner\_label\_prefix](#output\_runner\_label\_prefix) | Start of the runs-on label. Use codebuild-<name>-${{ github.run\_id }}-${{ github.run\_attempt }}. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the runner security group. |
<!-- END_TF_DOCS -->
