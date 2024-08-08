resource "aws_security_group" "expose_api_sg" {
  count = var.expose_api == "true" ? 1 : 0

  name        = "${var.cluster_name}-api-sg"
  description = "Allow traffic from outside VPC to kubernetes api over private link"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.cluster_name}-api-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "expose_api_sg" {
  count = var.expose_api == "true" ? 1 : 0

  security_group_id = aws_security_group.expose_api_sg[0].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "shell_script" "expose_api_sg" {
  count = var.expose_api == "true" ? 1 : 0

  lifecycle_commands {
    create = templatefile(
      "./scripts/expose-api.tftpl",
      {
        sg_id   = aws_security_group.expose_api_sg[0].id
        cluster = var.cluster_name
        enable  = true
    })
    delete = templatefile(
      "./scripts/expose-api.tftpl",
      {
        sg_id   = aws_security_group.expose_api_sg[0].id
        cluster = var.cluster_name
        enable  = false
    })
  }
  environment           = {}
  sensitive_environment = {}
  depends_on = [
    shell_script.cluster_seed
  ]
}
