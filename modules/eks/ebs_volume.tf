# Doc: https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/examples/kubernetes/storageclass/manifests/storageclass.yaml
# Doc: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1
locals {
  ebs_parameters = merge(
    {
      "csi.storage.k8s.io/fstype" = var.cluster_settings.addons.aws_ebs_csi_driver != null ? var.cluster_settings.addons.aws_ebs_csi_driver.fstype : ""
      "type"                      = var.cluster_settings.addons.aws_ebs_csi_driver != null ? var.cluster_settings.addons.aws_ebs_csi_driver.ebs_type : ""
      "encrypted"                 = var.cluster_settings.addons.aws_ebs_csi_driver != null ? var.cluster_settings.addons.aws_ebs_csi_driver.encrypted ? "true" : "false" : ""
    },
    var.cluster_settings.addons.aws_ebs_csi_driver == null ? {} : var.cluster_settings.addons.aws_ebs_csi_driver.iopsPerGB != null ?
    { "iopsPerGB" = tostring(var.cluster_settings.addons.aws_ebs_csi_driver.iopsPerGB) } : {}
  )
}

resource "kubernetes_storage_class_v1" "ebs" {
  count = var.cluster_settings == null || var.node_settings == null ? 0 : var.cluster_settings.addons.aws_ebs_csi_driver != null ? 1 : 0

  metadata {
    name = "ebs"
  }

  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  parameters          = local.ebs_parameters

  depends_on = [
    data.aws_eks_cluster.cluster,
    aws_eks_addon.eks_pod_identity_agent,
    aws_eks_cluster.cluster,
    aws_eks_node_group.node,
    aws_eks_pod_identity_association.aws_efs_csi_driver,
    aws_eks_addon.aws_efs_csi_driver,
    aws_efs_file_system.eks
  ]
}