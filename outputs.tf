output "project_name" {
  description = "Name of the CodeBuild project."
  value       = aws_codebuild_project.this.name
}

output "project_arn" {
  description = "ARN of the CodeBuild project."
  value       = aws_codebuild_project.this.arn
}

output "role_arn" {
  description = "ARN of the CodeBuild service role."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the CodeBuild service role, always <name>-codebuild."
  value       = aws_iam_role.this.name
}

output "security_group_id" {
  description = "ID of the runner security group."
  value       = aws_security_group.this.id
}

output "runner_label_prefix" {
  description = "Start of the runs-on label. Use codebuild-<name>-$${{ github.run_id }}-$${{ github.run_attempt }}."
  value       = "codebuild-${var.name}"
}
