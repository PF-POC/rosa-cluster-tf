resource "aws_route53_zone" "cluster" {
  name = var.ingress.baseDomain
  vpc {
    vpc_id = module.vpc.vpc_id
  }
  tags = {
    Environment = var.ingress.baseDomain
  }
  depends_on = [
    shell_script.cluster_seed
  ]
}

resource "shell_script" "ingress" {
  for_each = var.ingress.ingresses

  lifecycle_commands {
    create = templatefile(
      "./scripts/cluster-ingress.tftpl",
      {
        secret             = "${var.cluster_name}-credentials"
        helm_chart         = var.ingress.helm_chart
        helm_chart_version = var.ingress.helm_chart_version
        baseDomain         = var.ingress.baseDomain
        subDomain          = try(each.value.subDomain, null)
        hosted-zone-id     = resource.aws_route53_zone.cluster.zone_id
        enable             = true
    })
    delete = templatefile(
      "./scripts/cluster-ingress.tftpl",
      {
        secret             = "${var.cluster_name}-credentials"
        helm_chart         = var.ingress.helm_chart
        helm_chart_version = var.ingress.helm_chart_version
        baseDomain         = var.ingress.baseDomain
        subDomain          = try(each.value.subDomain, null)
        hosted-zone-id     = resource.aws_route53_zone.cluster.zone_id
        enable             = false
    })
  }
  environment           = {}
  sensitive_environment = {}
  depends_on = [
    shell_script.cluster_seed
  ]
}
