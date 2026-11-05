# Changelog

## v1.1.0

- Add `egress_tcp_ports`. When it is set, the runner security group allows only TCP on those ports toward `egress_cidr_blocks`. The default (null) keeps the v1.0.0 rules.

## v1.0.0

- First release. Creates a CodeBuild-hosted GitHub Actions runner for one repository: the project in your VPC, a repository webhook for `WORKFLOW_JOB_QUEUED` events, a narrow service role, an egress-only security group and a log group.
- Authenticates with a Secrets Manager secret (`SECRETS_MANAGER`) or a CodeConnections connection (`CODECONNECTIONS`). The token never enters state.
