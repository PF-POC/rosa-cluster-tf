resource "aws_iam_policy" "rosa_ecr_access_policy_iam" {

  name        = "${var.cluster_name}-rosa-rosa-ecr-access"
  path        = "/"
  description = "Alow rosa to rotate ecr access secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "rosa_ecr_access_role_iam" {
  name = "${var.cluster_name}-rosa-ecr-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_endpoint_url}/${module.rhcs_cluster_rosa_hcp.oidc_config_id}"
        }
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${local.oidc_endpoint_url}/${module.rhcs_cluster_rosa_hcp.oidc_config_id}:sub" = "system:serviceaccount:ecr-secret-operator:ecr-secret-operator-controller-manager"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rosa_ecr_access_role_iam_attachment" {
  role       = aws_iam_role.rosa_ecr_access_role_iam.name
  policy_arn = aws_iam_policy.rosa_ecr_access_policy_iam.arn
}

