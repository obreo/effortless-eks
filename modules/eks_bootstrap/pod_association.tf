
data "aws_eks_cluster" "eks" {
  name = var.integrations.cluster_name
}
## 2. aws_ebs_csi_driver: latest
data "aws_eks_addon_version" "aws_ebs_csi_driver" {
  count              = var.integrations.aws_ebs_csi_driver != null ? 1 : 0
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = data.aws_eks_cluster.eks.version
  most_recent        = true
}
resource "aws_eks_addon" "aws_ebs_csi_driver" {
  count         = var.integrations.aws_ebs_csi_driver != null ? 1 : 0
  cluster_name  = data.aws_eks_cluster.eks.name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = data.aws_eks_addon_version.aws_ebs_csi_driver[count.index].version

  lifecycle {
    ignore_changes = [addon_version]
  }
}
# EKS Pod Identity Association: to attach IAM role with Service account
resource "aws_eks_pod_identity_association" "aws_ebs_csi_driver" {
  count           = var.integrations.aws_ebs_csi_driver != null ? 1 : 0
  cluster_name    = data.aws_eks_cluster.eks.name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.aws_ebs_csi_driver[count.index].arn
}

## 3. aws_efs_csi_driver: latest
data "aws_eks_addon_version" "aws_efs_csi_driver" {
  count              = var.integrations.aws_efs_csi_driver == null || var.integrations.aws_efs_csi_driver.enable == false ? 0 : 1
  addon_name         = "aws-efs-csi-driver"
  kubernetes_version = data.aws_eks_cluster.eks.version
  most_recent        = true
}
resource "aws_eks_addon" "aws_efs_csi_driver" {
  count              = var.integrations.aws_efs_csi_driver == null || var.integrations.aws_efs_csi_driver.enable == false ? 0 : 1
  cluster_name  = data.aws_eks_cluster.eks.name
  addon_name    = "aws-efs-csi-driver"
  addon_version = data.aws_eks_addon_version.aws_efs_csi_driver[count.index].version

  lifecycle {
    ignore_changes = [addon_version]
  }
}
resource "aws_eks_pod_identity_association" "aws_efs_csi_driver" {
  count              = var.integrations.aws_efs_csi_driver == null ? 0 : var.integrations.aws_mountpoint_s3_csi_driver.enable ? 1 : 0
  cluster_name    = data.aws_eks_cluster.eks.name
  namespace       = "kube-system"
  service_account = "efs-csi-controller-sa"
  role_arn        = aws_iam_role.aws_efs_csi_driver[count.index].arn

}

## 4. aws-mountpoint-s3-csi-driver: latest
data "aws_eks_addon_version" "aws-mountpoint-s3-csi-driver" {
  count              = var.integrations.aws_mountpoint_s3_csi_driver == null ? 0 : 1
  addon_name         = "aws-mountpoint-s3-csi-driver"
  kubernetes_version = data.aws_eks_cluster.eks.version
  most_recent        = true
}
resource "aws_eks_addon" "aws-mountpoint-s3-csi-driver" {
  count              =  var.integrations.aws_mountpoint_s3_csi_driver == null ? 0 : 1
  cluster_name  = data.aws_eks_cluster.eks.name
  addon_name    = "aws-mountpoint-s3-csi-driver"
  addon_version = data.aws_eks_addon_version.aws-mountpoint-s3-csi-driver[count.index].version

  lifecycle {
    ignore_changes = [addon_version]
  }
}
resource "aws_eks_pod_identity_association" "s3" {
  count           = var.integrations.aws_mountpoint_s3_csi_driver == null ? 0 : 1
  cluster_name    = data.aws_eks_cluster.eks.name
  namespace       = "kube-system"
  service_account = "s3-csi-driver-sa"
  role_arn        = aws_iam_role.aws_mountpoint_s3_csi_driver[count.index].arn

}