# Create an S3 bucket where the application's zip file shall be stored.
resource "aws_s3_bucket" "bucket" {
  count = var.node_settings == null || var.cluster_settings.addons.aws_mountpoint_s3_csi_driver == null ? 0 : var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.enable && var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.s3_bucket_arn == "" ? 1 : 0

  bucket        = lower("${var.metadata.name}-eks-driver")
  force_destroy = true
}

# Bucket policy
resource "aws_s3_bucket_policy" "allow_access" {
  count  = var.node_settings == null || var.cluster_settings.addons.aws_mountpoint_s3_csi_driver == null ? 0 : var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.enable && var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.s3_bucket_arn == "" ? 1 : 0
  bucket = aws_s3_bucket.bucket[count.index].id
  policy = data.aws_iam_policy_document.allow_access.json
}
data "aws_iam_policy_document" "allow_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = length(aws_s3_bucket.bucket) > 0 ? [
      aws_s3_bucket.bucket[0].arn,
      "${aws_s3_bucket.bucket[0].arn}/*"
    ] : []
  }
}

# Doc:https://medium.com/bestcloudforme/managing-persistent-storage-with-amazon-s3-on-amazon-eks-9c2185817e83
# Doc: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1
resource "kubernetes_storage_class_v1" "s3" {
  count = var.node_settings == null || var.cluster_settings.addons.aws_mountpoint_s3_csi_driver == null ? 0 : var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.enable && var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.s3_bucket_arn == "" ? 1 : 0
  metadata {
    name = "s3-csi"
  }
  storage_provisioner = "s3.csi.aws.com"
  parameters = {
    type = "standard"
  }
  mount_options = ["iam"]

  depends_on = [
    data.aws_eks_cluster.cluster,
    aws_eks_addon.eks_pod_identity_agent,
    aws_eks_cluster.cluster,
    aws_eks_node_group.node,
    aws_eks_addon.kube-proxy,
    aws_eks_pod_identity_association.s3,
    aws_eks_addon.aws-mountpoint-s3-csi-driver,
    aws_s3_bucket.bucket
  ]
}


# Create VPC endpoint for S3
data "aws_subnet" "selected" {
  count = var.node_settings == null || var.cluster_settings.addons.aws_mountpoint_s3_csi_driver == null  ? 0 : var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.enable && var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.create_vpc_endpoint != null ? 1 : 0
  id = var.cluster_settings.cluster_subnet_ids[0]
}
resource "aws_vpc_endpoint" "s3" {
  count = var.node_settings == null || var.cluster_settings.addons.aws_mountpoint_s3_csi_driver == null  ? 0 : var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.enable && var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.create_vpc_endpoint != null ? 1 : 0
  vpc_id       = data.aws_subnet.selected[count.index].vpc_id
  service_name = var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.create_vpc_endpoint.bucket_region != "" ? "com.amazonaws.${ var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.create_vpc_endpoint.bucket_region}.s3" : "com.amazonaws.${var.metadata.region}.s3"
  route_table_ids = var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.create_vpc_endpoint.route_table_ids != [] ? var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.create_vpc_endpoint.route_table_ids : []
}