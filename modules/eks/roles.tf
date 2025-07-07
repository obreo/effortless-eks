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
resource "aws_iam_role_policy_attachment" "AmazonEKSCNIIPv6Policy" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.AmazonEKSCNIIPv6Policy.arn
}
resource "aws_iam_policy" "AmazonEKSCNIIPv6Policy" {
  name        = "AmazonEKS_CNI_IPv6_Policy"
  path        = "/"
  description = "IPv6 policies to attach to worker-node"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:AssignIpv6Addresses",
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeInstanceTypes"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:CreateTags"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ec2:*:*:network-interface/*"
      },
    ]
  })
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
  count = var.node_settings == null ? 0 : 1
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
  count  = var.node_settings == null ? 0 : 1
  policy = file("${path.module}/iam-policies/alb.json")
  name   = "AWSLoadBalancerController-${var.metadata.name}"
}

## Role Policy Attachement
resource "aws_iam_role_policy_attachment" "alb" {
  count      = var.node_settings == null ? 0 : 1
  role       = aws_iam_role.alb[count.index].name
  policy_arn = aws_iam_policy.alb[count.index].arn
}