# ASSOCIATED IAM USERS & ROLES
# 1. EKS CLUSTER ROLE
resource "aws_iam_role" "cluster" {
  name = "${var.metadata.name}-EKSClusterRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}
## POLICIES
resource "aws_iam_role_policy_attachment" "amazoneksvpcresourcecontroller" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}
resource "aws_iam_role_policy_attachment" "amazoneksclusterPolicy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# 2. EKS NODE ROLE
resource "aws_iam_role" "node" {

  name = "${var.metadata.name}-EKSWorkerNodeRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
## POLICIES
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}



#######################################################
# ServiceAccount IAM Roles

## 1. Cluster-Autoscaler
### Role
resource "aws_iam_role" "cluster-autoscaler" {
  name = "${var.metadata.name}-eks-cluster-autoscaler"
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
### Policy
resource "aws_iam_policy" "cluster-autoscaler" {
  name = "${var.metadata.name}-eks-cluster-autoscaler"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeAutoScalingInstances",
            "autoscaling:DescribeLaunchConfigurations",
            "autoscaling:DescribeScalingActivities",
            "ec2:DescribeImages",
            "ec2:DescribeInstanceTypes",
            "ec2:DescribeLaunchTemplateVersions",
            "ec2:GetInstanceTypesFromInstanceRequirements",
            "eks:DescribeNodegroup"
          ],
          "Resource" : ["*"]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "autoscaling:SetDesiredCapacity",
            "autoscaling:TerminateInstanceInAutoScalingGroup"
          ],
          "Resource" : ["*"]
        }
      ]
    }
  )
}
### Role Policy Attachment
resource "aws_iam_role_policy_attachment" "cluster-autoscaler" {
  role       = aws_iam_role.cluster-autoscaler.name
  policy_arn = aws_iam_policy.cluster-autoscaler.arn
}


## 2. aws_ebs_csi_driver
### Role
resource "aws_iam_role" "aws_ebs_csi_driver" {
  count = var.cluster_settings == null ? 0 : var.cluster_settings.addons.aws_ebs_csi_driver != null ? 1 : 0
  name  = "${var.metadata.name}-aws-ebs-csi-driver"
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
  count      = var.cluster_settings == null ? 0 : var.cluster_settings.addons.aws_ebs_csi_driver != null ? 1 : 0
  role       = aws_iam_role.aws_ebs_csi_driver[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

## 3. aws_efs_csi_driver
### Role
resource "aws_iam_role" "aws_efs_csi_driver" {
  count = var.cluster_settings == null ? 0 : var.cluster_settings.addons.aws_efs_csi_driver == null ? 0 : var.cluster_settings.addons.aws_efs_csi_driver.enable ? 1 : 0
  name  = "${var.metadata.name}-aws-efs-csi-driver"
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
  count      = var.cluster_settings == null ? 0 : var.cluster_settings.addons.aws_efs_csi_driver.enable ? 1 : 0
  role       = aws_iam_role.aws_efs_csi_driver[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

## 3. aws_mountpoint_s3_csi_driver
### Role
resource "aws_iam_role" "aws_mountpoint_s3_csi_driver" {
  count = var.cluster_settings == null ? 0 : var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.enable ? 1 : 0
  name  = "${var.metadata.name}-aws-mountpoint-s3-csi-driver"
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
  count = var.cluster_settings == null ? 0 : var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.enable ? 1 : 0
  name  = "${var.metadata.name}-aws-mountpoint-s3-csi-driver"
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
            "${var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.s3_bucket_arn == "" ? aws_s3_bucket.bucket[0].arn : var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.s3_bucket_arn}"
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
            "${var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.s3_bucket_arn == "" ? aws_s3_bucket.bucket[0].arn : var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.s3_bucket_arn}"
          ]
        }
      ]
    }
  )
}
### Role Policy Attachment
resource "aws_iam_role_policy_attachment" "aws_mountpoint_s3_csi_driver" {
  count      = var.cluster_settings == null ? 0 : var.cluster_settings.addons.aws_mountpoint_s3_csi_driver.enable ? 1 : 0
  role       = aws_iam_role.aws_mountpoint_s3_csi_driver[count.index].name
  policy_arn = aws_iam_policy.aws_mountpoint_s3_csi_driver[count.index].arn
}

## 4. amazon_cloudwatch_observability
### Role
resource "aws_iam_role" "amazon_cloudwatch_observability" {
  count = var.cluster_settings == null ? 0 : var.cluster_settings.addons.amazon_cloudwatch_observability ? 1 : 0
  name  = "${var.metadata.name}-amazon-cloudwatch-observability"
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
resource "aws_iam_role_policy_attachment" "amazon_cloudwatch_observability" {
  count      = var.cluster_settings == null ? 0 : var.cluster_settings.addons.amazon_cloudwatch_observability ? 1 : 0
  role       = aws_iam_role.amazon_cloudwatch_observability[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "amazon_cloudwatch_observability_2" {
  count      = var.cluster_settings == null ? 0 : var.cluster_settings.addons.amazon_cloudwatch_observability ? 1 : 0
  role       = aws_iam_role.amazon_cloudwatch_observability[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# 5. Appliaction Load Balancer Controller
## Role & Assume Role Policy
resource "aws_iam_role" "alb" {
  count = var.node_settings == null || var.plugins == null ? 0 : var.plugins.aws_alb_controller != null ? 1 : 0
  name  = "${var.metadata.name}-alb-controller"
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

## Policy
resource "aws_iam_policy" "alb" {
  count  = var.node_settings == null || var.plugins == null ? 0 : var.plugins.aws_alb_controller != null ? 1 : 0
  policy = file("${path.module}/iam-policies/alb.json")
  name   = "AWSLoadBalancerController-${var.metadata.name}"
}

## Role Policy Attachement
resource "aws_iam_role_policy_attachment" "alb" {
  count      = var.node_settings == null || var.plugins == null ? 0 : var.plugins.aws_alb_controller != null ? 1 : 0
  role       = aws_iam_role.alb[count.index].name
  policy_arn = aws_iam_policy.alb[count.index].arn
}