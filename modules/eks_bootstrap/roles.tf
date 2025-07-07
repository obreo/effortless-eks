## aws_ebs_csi_driver
### Role
resource "aws_iam_role" "aws_ebs_csi_driver" {
  count = var.integrations.aws_ebs_csi_driver == null ? 0 : 1
  name  = "${lower(replace(data.aws_eks_cluster.eks.name, "_", "-"))}-aws-ebs-csi-driver"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole", "sts:TagSession"]
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
      },
    ]
  })
}
### Role Policy Attachment
resource "aws_iam_role_policy_attachment" "aws_ebs_csi_driver" {
  count = var.integrations.aws_efs_csi_driver == null ? 0 : var.integrations.aws_efs_csi_driver.enable ? 1 : 0
  role       = aws_iam_role.aws_ebs_csi_driver[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

## 3. aws_efs_csi_driver
### Role
resource "aws_iam_role" "aws_efs_csi_driver" {
  count = var.integrations.aws_efs_csi_driver == null ? 0 : var.integrations.aws_efs_csi_driver.enable ? 1 : 0
  name  = "${lower(replace(data.aws_eks_cluster.eks.name, "_", "-"))}-aws-efs-csi-driver"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole", "sts:TagSession"]
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
      },
    ]
  })
}
### Role Policy Attachment
resource "aws_iam_role_policy_attachment" "aws_efs_csi_driver" {
  count = var.integrations.aws_efs_csi_driver == null ? 0 : var.integrations.aws_efs_csi_driver.enable ? 1 : 0
  role       = aws_iam_role.aws_efs_csi_driver[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

## 3. aws_mountpoint_s3_csi_driver
### Role
resource "aws_iam_role" "aws_mountpoint_s3_csi_driver" {
  count = var.integrations.aws_mountpoint_s3_csi_driver == null ? 0 : 1
  name  = "${lower(replace(data.aws_eks_cluster.eks.name, "_", "-"))}-aws-mountpoint-s3-csi-driver"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole", "sts:TagSession"]
        Effect = "Allow"
        Principal = {
          Service = ["pods.eks.amazonaws.com", "eks.amazonaws.com"]
        }
      },
    ]
  })
}
### Policy
resource "aws_iam_policy" "aws_mountpoint_s3_csi_driver" {
  count = var.integrations.aws_mountpoint_s3_csi_driver == null ? 0 : 1
  name  = "${lower(replace(data.aws_eks_cluster.eks.name, "_", "-"))}-aws-mountpoint-s3-csi-driver"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "MountpointFullBucketAccess",
          "Effect" : "Allow",
          "Action" : [
            "s3:ListBucket"
          ],
          "Resource" : [
            "${var.integrations.aws_mountpoint_s3_csi_driver.s3_bucket_arn == "" ? aws_s3_bucket.bucket[0].arn : var.integrations.aws_mountpoint_s3_csi_driver.s3_bucket_arn}"
          ]
        },
        {
          "Sid" : "MountpointFullObjectAccess",
          "Effect" : "Allow",
          "Action" : [
            "s3:GetObject",
            "s3:PutObject",
            "s3:AbortMultipartUpload",
            "s3:DeleteObject"
          ],
          "Resource" : [
            "${var.integrations.aws_mountpoint_s3_csi_driver.s3_bucket_arn == "" ? aws_s3_bucket.bucket[0].arn : var.integrations.aws_mountpoint_s3_csi_driver.s3_bucket_arn}"
          ]
        }
      ]
    }
  )
}
### Role Policy Attachment
resource "aws_iam_role_policy_attachment" "aws_mountpoint_s3_csi_driver" {
  count = var.integrations.aws_mountpoint_s3_csi_driver == null ? 0 : 1
  role       = aws_iam_role.aws_mountpoint_s3_csi_driver[count.index].name
  policy_arn = aws_iam_policy.aws_mountpoint_s3_csi_driver[count.index].arn
}