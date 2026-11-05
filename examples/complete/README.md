# Complete example

Creates a VPC with NAT, an empty Secrets Manager secret and a runner for `acme/infra`.

1. Create the secret first, because the webhook fails to create until the secret has a value: `tofu apply -target=aws_secretsmanager_secret.github_token`.
2. Put the token in the secret. CodeBuild needs this JSON shape:

   ```bash
   aws secretsmanager put-secret-value --secret-id example-runner-github-token \
     --secret-string '{"ServerType":"GITHUB","AuthType":"PERSONAL_ACCESS_TOKEN","Token":"<token>"}'
   ```

3. Apply the rest, then set `runs-on` in the workflow to the `runs_on` output.

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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_runner"></a> [runner](#module\_runner) | ../.. | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 6.7 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_secretsmanager_secret.github_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_runs_on"></a> [runs\_on](#output\_runs\_on) | Value for runs-on in the workflow. |
<!-- END_TF_DOCS -->
