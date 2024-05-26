# https://cloud.redhat.com/experts/rosa/aws-efs/

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "rosa_efs_csi_policy_iam" {
  count       = var.efs ? 1 : 0
  name        = "${var.cluster_name}-rosa-efs-csi"
  path        = "/"
  description = "AWS EFS CSI Driver Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets",
          "elasticfilesystem:TagResource",
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:CreateAccessPoint"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:RequestTag/efs.csi.aws.com/cluster" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DeleteAccessPoint",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/efs.csi.aws.com/cluster" = "true"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "rosa_efs_csi_role_iam" {
  count = var.efs ? 1 : 0
  name  = "${var.cluster_name}-rosa-efs-csi-role-iam"

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
            "oidc.op1.openshiftapps.com/${module.rhcs_cluster_rosa_hcp.oidc_config_id}:sub" = [
              "system:serviceaccount:openshift-cluster-csi-drivers:aws-efs-csi-driver-operator",
              "system:serviceaccount:openshift-cluster-csi-drivers:aws-efs-csi-driver-controller-sa"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rosa_efs_csi_role_iam_attachment" {
  count      = var.efs ? 1 : 0
  role       = aws_iam_role.rosa_efs_csi_role_iam[0].name
  policy_arn = aws_iam_policy.rosa_efs_csi_policy_iam[0].arn
}

resource "aws_efs_file_system" "rosa_efs" {
  count          = var.efs ? 1 : 0
  creation_token = "efs-token-1"
  encrypted      = true
  tags = {
    Name = "${var.cluster_name}-rosa-efs"
  }
}

resource "aws_efs_mount_target" "efs_mount_worker_0" {
  for_each = var.efs_mount_targets

  file_system_id  = try(each.value.aws_efs_file_system.rosa_efs_id, null)
  subnet_id       = try(each.value.subnet_id, null)
  security_groups = try(each.value.ec2_security_group_id, null)
  depends_on = [
    module.rhcs_cluster_rosa_hcp
  ]
}

resource "null_resource" "efs" {
  for_each = var.efs_mount_targets
  provisioner "local-exec" {
    command = "touch efs.log; scripts/efs.sh >> efs.log 2>&1"
    environment = {
      cluster = var.cluster_name
    }
  }
  depends_on = [
    module.rhcs_cluster_rosa_hcp
  ]
}

