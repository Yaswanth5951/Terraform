
resource "aws_security_group" "private" {
  description = var.security_group_info.description
  name        = var.security_group_info.name
  vpc_id      = var.security_group_info.vpc_id
}

resource "aws_security_group_rule" "allowssh" {
  count             = length(var.security_group_info.rules)
  from_port         = var.security_group_info.rules[count.index].from_port
  to_port           = var.security_group_info.rules[count.index].to_port
  type              = var.security_group_info.rules[count.index].type
  protocol          = var.security_group_info.rules[count.index].protocol
  security_group_id = aws_security_group.private.id
  cidr_blocks       = var.security_group_info.rules[count.index].cidr_blocks

}

