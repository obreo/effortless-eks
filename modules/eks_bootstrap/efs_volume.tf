# Deploying EFS and setting its storageClass in cluster
resource "aws_efs_file_system" "eks" {
  count          = var.integrations.aws_efs_csi_driver != null ? var.integrations.aws_efs_csi_driver.efs_resource_id == "" ? 1 : 0 : 0
  creation_token = "eks"
  encrypted      = var.integrations.aws_efs_csi_driver.encrypted ? true : false
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  tags = {
    CreatedFor = "${var.integrations.aws_efs_csi_driver.name}"
  }
}

resource "aws_efs_mount_target" "eks" {
  count           = var.integrations.aws_efs_csi_driver == null ? 0 : var.integrations.aws_efs_csi_driver.efs_resource_id == "" ? length(var.integrations.aws_efs_csi_driver.subnet_ids) : 0
  file_system_id  = aws_efs_file_system.eks[0].id
  subnet_id       = var.integrations.aws_efs_csi_driver.subnet_ids[count.index]
  security_groups = var.integrations.aws_efs_csi_driver.security_groups
}


data "aws_iam_policy_document" "policy" {
  count          = var.integrations.aws_efs_csi_driver == null ? 0 : var.integrations.aws_efs_csi_driver.efs_resource_id == "" ? 1 : 0
  statement {
    sid    = "ExampleStatement01"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]

    resources = [aws_efs_file_system.eks[0].arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
    condition {
      test     = "Bool"
      variable = "elasticfilesystem:AccessedViaMountTarget"
      values   = ["true"]
    }
  }
}

resource "aws_efs_file_system_policy" "policy" {
  count          = var.integrations.aws_efs_csi_driver == null ? 0 : var.integrations.aws_efs_csi_driver.efs_resource_id == "" ? 1 : 0
  file_system_id = aws_efs_file_system.eks[count.index].id
  policy         = data.aws_iam_policy_document.policy[count.index].json
}

# StorageClass definition
# Doc: https://kubernetes.io/docs/concepts/storage/storage-classes/#aws-efs
# Doc: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1
resource "kubernetes_storage_class_v1" "efs" {
  count = var.integrations.aws_efs_csi_driver == null ? 0 : var.integrations.aws_efs_csi_driver.efs_resource_id == "" ? 1 : 0
  metadata {
    name = "efs"
  }
  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = var.integrations.aws_efs_csi_driver.efs_resource_id != "" ? var.integrations.aws_efs_csi_driver.efs_resource_id : aws_efs_file_system.eks[count.index].id
    directoryPerms   = "700"
  }
  mount_options = ["iam"]
}