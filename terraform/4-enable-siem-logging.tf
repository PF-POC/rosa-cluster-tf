
locals {
  cloudwatch_siem_role_iam_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-rosa-cloudwatch-siem-role-iam"
}

resource "aws_iam_policy" "rosa_cloudwatch_siem_policy_iam" {
  count = var.enable-siem-logging == "true" ? 1 : 0

  name        = "${var.cluster_name}-rosa-cloudwatch-siem"
  path        = "/"
  description = "RosaCloudWatch Siem logging"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:PutRetentionPolicy"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role" "rosa_cloudwatch_siem_role_iam" {
  count = var.enable-siem-logging == "true" ? 1 : 0

  name = "${var.cluster_name}-rosa-cloudwatch-siem-role-iam"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.op1.openshiftapps.com/${module.rhcs_cluster_rosa_hcp.oidc_config_id}"
        }
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "oidc.op1.openshiftapps.com/${module.rhcs_cluster_rosa_hcp.oidc_config_id}:sub" = "system:serviceaccount:openshift-config-managed:cloudwatch-audit-exporter"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rosa_cloudwatch_siem_role_iam_attachment" {
  count = var.enable-siem-logging == "true" ? 1 : 0

  role       = aws_iam_role.rosa_cloudwatch_siem_role_iam[0].name
  policy_arn = aws_iam_policy.rosa_cloudwatch_siem_policy_iam[0].arn
}

output "rosa_cloudwatch_siem_role_iam_arn" {
  value       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-rosa-cloudwatch-siem-role-iam"
  description = "Cloudwatch arn to add to helm chart deployment."
}

# resource "null_resource" "enable-siem-logging" {
#   count = var.enable-siem-logging == "true" ? 1 : 0

#   provisioner "local-exec" {
#     command = "scripts/enable-siem-logging.sh > enable-siem-logging.log 2>&1"
#     environment = {
#       secret        = "${var.cluster_name}-credentials"
#       cluster       = var.cluster_name
#       cluster_id    = module.rhcs_cluster_rosa_hcp.rosa_cluster_hcp_cluster_id
#       siem_role_arn = local.cloudwatch_siem_role_iam_arn
#     }
#   }
# }

resource "shell_script" "enable_siem_logging" {
  count = var.enable-siem-logging == "true" ? 1 : 0

  lifecycle_commands {
    create = templatefile(
      "./scripts/enable-siem-logging.tftpl",
      {
        siem_role_arn = local.cloudwatch_siem_role_iam_arn
        cluster       = var.cluster_name
        enable        = true
        token         = var.token
    })
    delete = templatefile(
      "./scripts/enable-siem-logging.tftpl",
      {
        siem_role_arn = local.cloudwatch_siem_role_iam_arn
        cluster       = var.cluster_name
        enable        = false
        token         = var.token
    })
  }
  environment           = {}
  sensitive_environment = {}
  depends_on = [
    shell_script.cluster_seed
  ]
}
