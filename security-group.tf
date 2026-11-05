resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "CodeBuild runner ${var.name}: egress only"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = toset(var.egress_cidr_blocks)

  security_group_id = aws_security_group.this.id
  description       = "Runner egress to ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "-1"

  tags = var.tags
}
