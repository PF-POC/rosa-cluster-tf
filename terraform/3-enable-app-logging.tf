# https://docs.openshift.com/rosa/cloud_experts_tutorials/cloud-experts-rosa-cloudwatch-sts.html

#data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "rosa_cloudwatch_policy_iam" {
  name        = "${var.cluster_name}-rosa-cloudwatch"
  path        = "/"
  description = "RosaCloudWatch"

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

resource "aws_iam_role" "rosa_cloudwatch_role_iam" {
  name = "${var.cluster_name}-rosa-cloudwatch-role-iam"

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
            "oidc.op1.openshiftapps.com/${module.rhcs_cluster_rosa_hcp.oidc_config_id}:sub" = "system:serviceaccount:openshift-logging:logcollector"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rosa_cloudwatch_role_iam_attachment" {
  role       = aws_iam_role.rosa_cloudwatch_role_iam.name
  policy_arn = aws_iam_policy.rosa_cloudwatch_policy_iam.arn
}

output "rosa_cloudwatch_role_iam_arn" {
  value       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-rosa-cloudwatch-role-iam"
  description = "Cloudwatch arn to add to helm chart deployment."
}