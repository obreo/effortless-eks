# Deploying S3 bucket and integrating storageClass resource
resource "aws_s3_bucket" "bucket" {
  count = var.integrations.aws_mountpoint_s3_csi_driver != null ? var.integrations.aws_mountpoint_s3_csi_driver.s3_bucket_arn == "" ? 1 : 0 : 0

  bucket        = lower("${var.integrations.aws_mountpoint_s3_csi_driver.name}-eks-driver")
  force_destroy = true
}

# Bucket policy
## Get current IAM user
data "aws_caller_identity" "current" {}
resource "aws_s3_bucket_policy" "allow_access" {
  count  = var.integrations.aws_mountpoint_s3_csi_driver != null ? var.integrations.aws_mountpoint_s3_csi_driver.s3_bucket_arn == "" ? 1 : 0 : 0
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

    resources = [
      aws_s3_bucket.bucket[0].arn,
      "${aws_s3_bucket.bucket[0].arn}/*"
    ]
  }
}

# Doc:https://medium.com/bestcloudforme/managing-persistent-storage-with-amazon-s3-on-amazon-eks-9c2185817e83
# Doc: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1
resource "kubernetes_storage_class_v1" "s3" {
  count = var.integrations.aws_mountpoint_s3_csi_driver != null ? var.integrations.aws_mountpoint_s3_csi_driver.s3_bucket_arn == "" ? 1 : 0 : 0
  metadata {
    name = "s3-csi"
  }
  storage_provisioner = "s3.csi.aws.com"
  parameters = {
    type = "standard"
  }
  mount_options = ["iam"]

  depends_on = [
    aws_s3_bucket.bucket
  ]
}


# Create VPC endpoint for S3

data "aws_route_tables" "rts" {
    vpc_id = var.integrations.aws_mountpoint_s3_csi_driver.create_vpc_endpoint.vpc_id
}
resource "aws_vpc_endpoint" "s3" {
  count = var.integrations.aws_mountpoint_s3_csi_driver != null ? var.integrations.aws_mountpoint_s3_csi_driver.create_vpc_endpoint != null ? 1 : 0 : 0
  vpc_id       = var.integrations.aws_mountpoint_s3_csi_driver.create_vpc_endpoint.vpc_id
  service_name = var.integrations.aws_mountpoint_s3_csi_driver.create_vpc_endpoint.bucket_region != "" ? "com.amazonaws.${ var.integrations.aws_mountpoint_s3_csi_driver.create_vpc_endpoint.bucket_region}.s3" : "com.amazonaws.${data.aws_route_tables.rts.ids}.s3"
  route_table_ids = var.integrations.aws_mountpoint_s3_csi_driver.create_vpc_endpoint.route_table_ids != [] ? var.integrations.aws_mountpoint_s3_csi_driver.create_vpc_endpoint.route_table_ids : data.aws_route_tables.rts.ids
}