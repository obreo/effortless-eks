# Setting StorageClass
# Doc: https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/examples/kubernetes/storageclass/manifests/storageclass.yaml
# Doc: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1
locals {
  ebs_parameters = merge(
    {
      "csi.storage.k8s.io/fstype" = var.integrations.aws_ebs_csi_driver != null ? var.integrations.aws_ebs_csi_driver.fstype : ""
      "type"                      = var.integrations.aws_ebs_csi_driver != null ? var.integrations.aws_ebs_csi_driver.ebs_type : ""
      "encrypted"                 = var.integrations.aws_ebs_csi_driver != null ? var.integrations.aws_ebs_csi_driver.encrypted ? "true" : "false" : ""
    },
    var.integrations.aws_ebs_csi_driver == null ? {} : var.integrations.aws_ebs_csi_driver.iopsPerGB != null ?
    { "iopsPerGB" = tostring(var.integrations.aws_ebs_csi_driver.iopsPerGB) } : {}
  )
}

resource "kubernetes_storage_class_v1" "ebs" {
  count = var.integrations.aws_ebs_csi_driver != null ? 1 : 0

  metadata {
    name = "ebs"
  }

  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  parameters          = local.ebs_parameters

}