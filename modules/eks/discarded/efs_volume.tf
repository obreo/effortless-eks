resource "aws_efs_file_system" "eks" {
  count          = var.cluster_settings == null || var.node_settings == null || var.cluster_settings.addons.aws_efs_csi_driver == null ? 0 : var.cluster_settings.addons.aws_efs_csi_driver.enable && var.cluster_settings.addons.aws_efs_csi_driver.efs_resource_id == "" ? 1 : 0
  creation_token = "eks"
  encrypted      = var.cluster_settings.addons.aws_efs_csi_driver.encrypted ? true : false
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  tags = {
    CreatedBy = "${var.metadata.name}"
  }
  depends_on = [
    aws_eks_addon.eks_pod_identity_agent,
    aws_eks_cluster.cluster,
    aws_eks_node_group.node,
    aws_eks_pod_identity_association.aws_efs_csi_driver,
    aws_eks_addon.aws_efs_csi_driver
  ]
}

resource "aws_efs_mount_target" "eks" {
  count           =var.cluster_settings == null || var.node_settings == null || var.cluster_settings.addons.aws_efs_csi_driver == null ? 0 : var.cluster_settings.addons.aws_efs_csi_driver.enable && var.cluster_settings.addons.aws_efs_csi_driver.efs_resource_id == "" ? length(var.cluster_settings.addons.aws_efs_csi_driver.subnet_ids) : 0
  file_system_id  = aws_efs_file_system.eks[0].id
  subnet_id       = var.cluster_settings.addons.aws_efs_csi_driver.subnet_ids[count.index]
  security_groups = aws_eks_cluster.cluster[0].vpc_config[0].security_group_ids != [] ? aws_eks_cluster.cluster[0].vpc_config[0].security_group_ids : [aws_eks_cluster.cluster[0].vpc_config[0].cluster_security_group_id]
  depends_on = [
    aws_eks_addon.eks_pod_identity_agent,
    aws_eks_cluster.cluster,
    aws_eks_node_group.node,
    aws_eks_pod_identity_association.aws_efs_csi_driver,
    aws_eks_addon.aws_efs_csi_driver
  ]
}


data "aws_iam_policy_document" "policy" {
  count          = var.cluster_settings == null || var.node_settings == null || var.cluster_settings.addons.aws_efs_csi_driver == null ? 0 : var.cluster_settings.addons.aws_efs_csi_driver.enable && var.cluster_settings.addons.aws_efs_csi_driver.efs_resource_id == "" ? 1 : 0
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
  count          = var.cluster_settings == null || var.node_settings == null || var.cluster_settings.addons.aws_efs_csi_driver == null ? 0 : var.cluster_settings.addons.aws_efs_csi_driver.enable && var.cluster_settings.addons.aws_efs_csi_driver.efs_resource_id == "" ? 1 : 0
  file_system_id = aws_efs_file_system.eks[count.index].id
  policy         = data.aws_iam_policy_document.policy[count.index].json
  depends_on = [
    aws_eks_addon.eks_pod_identity_agent,
    aws_eks_cluster.cluster,
    aws_eks_node_group.node,
    aws_eks_pod_identity_association.aws_efs_csi_driver,
    aws_eks_addon.aws_efs_csi_driver
  ]
}

# Doc: https://kubernetes.io/docs/concepts/storage/storage-classes/#aws-efs
# Doc: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1
resource "kubernetes_storage_class_v1" "efs" {
  count = var.cluster_settings == null || var.node_settings == null || var.cluster_settings.addons.aws_efs_csi_driver == null ? 0 : var.cluster_settings.addons.aws_efs_csi_driver.enable && var.cluster_settings.addons.aws_efs_csi_driver.efs_resource_id == "" ? 1 : 0
  metadata {
    name = "efs"
  }
  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = var.cluster_settings.addons.aws_efs_csi_driver.efs_resource_id != "" ? var.cluster_settings.addons.aws_efs_csi_driver.efs_resource_id : aws_efs_file_system.eks[count.index].id
    directoryPerms   = "700"
  }
  mount_options = ["iam"]

  depends_on = [
    aws_eks_addon.eks_pod_identity_agent,
    aws_eks_cluster.cluster,
    aws_eks_node_group.node,
    aws_eks_pod_identity_association.aws_efs_csi_driver,
    aws_eks_addon.aws_efs_csi_driver,
    aws_efs_file_system.eks
  ]
}