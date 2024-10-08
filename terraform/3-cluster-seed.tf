# Creating a AWS secret

resource "aws_secretsmanager_secret" "secret" {
  count                   = var.seed.deploy == "true" ? 1 : 0
  name                    = "${var.cluster_name}-credentials"
  recovery_window_in_days = 0
  depends_on = [
    module.rhcs_cluster_rosa_hcp
  ]
}

# Creating a AWS secret versions

resource "aws_secretsmanager_secret_version" "sversion" {
  count         = var.seed.deploy == "true" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.secret[0].id
  secret_string = <<EOF
   {
    "user": "cluster-admin",
    "password": "initial"
   }
EOF
}

resource "shell_script" "cluster_seed" {
  count = var.seed.deploy == "true" ? 1 : 0

  lifecycle_commands {
    create = templatefile(
      "./scripts/cluster-seed.tftpl",
      {
        secret             = "${var.cluster_name}-credentials"
        token              = var.token
        cluster            = var.cluster_name
        secret_id          = aws_secretsmanager_secret.secret[0].id
        helm_chart         = var.seed.helm_chart
        helm_chart_version = var.seed.helm_chart_version
        gitPath            = var.seed.gitPath
        ecrArn             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-rosa-ecr-access-role"
        mode               = "enable"
    })
    delete = templatefile(
      "./scripts/cluster-seed.tftpl",
      {
        secret             = "${var.cluster_name}-credentials"
        token              = var.token
        cluster            = var.cluster_name
        secret_id          = aws_secretsmanager_secret.secret[0].id
        helm_chart         = var.seed.helm_chart
        helm_chart_version = var.seed.helm_chart_version
        gitPath            = var.seed.gitPath
        ecrArn             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-rosa-ecr-access-role"
        mode               = "disable"
    })
  }
  environment           = {}
  sensitive_environment = {}
  depends_on = [
    module.rhcs_cluster_rosa_hcp
  ]
}