resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "CodeBuild runner ${var.name}: egress only"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    create_before_destroy = true
  }
}

# Runners need egress to GitHub; callers narrow it with egress_cidr_blocks.
#trivy:ignore:AVD-AWS-0104
resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = local.egress_rules

  security_group_id = aws_security_group.this.id
  description       = each.value.port == null ? "Runner egress to ${each.value.cidr}" : "Runner egress to ${each.value.cidr} on ${each.value.port}"
  cidr_ipv4         = each.value.cidr
  ip_protocol       = each.value.port == null ? "-1" : "tcp"
  from_port         = each.value.port
  to_port           = each.value.port

  tags = var.tags
}

locals {
  # One rule per CIDR, or per CIDR and port when egress_tcp_ports is set.
  egress_rules = var.egress_tcp_ports == null ? {
    for c in var.egress_cidr_blocks : c => { cidr = c, port = null }
    } : {
    for pair in setproduct(var.egress_cidr_blocks, var.egress_tcp_ports) : "${pair[0]}:${pair[1]}" => { cidr = pair[0], port = pair[1] }
  }
}
