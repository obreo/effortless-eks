# Authenticating External services with ServiceAccount
# Cluster Autoscaler EKS Pod Identity Association
# EKS Pod Identity Association: to attach IAM role with Service account
resource "aws_eks_pod_identity_association" "cluster-autoscaler" {
  count           = var.cluster_settings != null && var.node_settings != null ? 1 : 0
  cluster_name    = aws_eks_cluster.cluster[count.index].name
  namespace       = "kube-system"
  service_account = "cluster-autoscaler"
  role_arn        = aws_iam_role.cluster-autoscaler.arn
  depends_on      = [aws_eks_addon.eks_pod_identity_agent]
}

## Application Load Balancer Controller service account auth
resource "aws_eks_pod_identity_association" "alb" {
  count           = var.node_settings == null ? 0 : 1
  cluster_name    = var.metadata.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.alb[count.index].arn

  depends_on = [
    aws_eks_addon.eks_pod_identity_agent,
    aws_iam_role_policy_attachment.alb,
    aws_eks_node_group.node,
    aws_eks_cluster.cluster
  ]
}

# EKS native ADDONS
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version
# Doc: https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html
# VPC CNI
data "aws_eks_addon_version" "vpc-cni" {
  count              = var.cluster_settings != null && var.node_settings != null ? 1 : 0
  addon_name         = "vpc-cni"
  kubernetes_version = aws_eks_cluster.cluster[count.index].version
  most_recent        = true

}
resource "aws_eks_addon" "vpc-cni" {
  count         = var.cluster_settings == null || var.node_settings == null ? 0 : var.cluster_settings.addons.vpc_cni == false ? 0 : 1
  cluster_name  = aws_eks_cluster.cluster[count.index].name
  addon_name    = "vpc-cni"
  addon_version = data.aws_eks_addon_version.vpc-cni[count.index].version
  depends_on = [
    aws_eks_cluster.cluster
  ]
  lifecycle {
    ignore_changes = [addon_version]
  }
}

# CoreDNS
data "aws_eks_addon_version" "coredns" {
  count              = var.cluster_settings != null && var.node_settings != null ? 1 : 0
  addon_name         = "coredns"
  kubernetes_version = aws_eks_cluster.cluster[count.index].version
  most_recent        = true
}
resource "aws_eks_addon" "coredns" {
  count         = var.cluster_settings != null && var.node_settings != null ? 1 : 0
  cluster_name  = aws_eks_cluster.cluster[count.index].name
  addon_name    = "coredns"
  addon_version = data.aws_eks_addon_version.coredns[count.index].version
  depends_on = [
    aws_eks_cluster.cluster
  ]
  lifecycle {
    ignore_changes = all
  }
}

# Kube Proxy
data "aws_eks_addon_version" "kube-proxy" {
  count              = var.cluster_settings != null && var.node_settings != null ? 1 : 0
  addon_name         = "kube-proxy"
  kubernetes_version = aws_eks_cluster.cluster[count.index].version
  most_recent        = true
}
resource "aws_eks_addon" "kube-proxy" {
  count         = var.cluster_settings != null && var.node_settings != null ? 1 : 0
  cluster_name  = aws_eks_cluster.cluster[count.index].name
  addon_name    = "kube-proxy"
  addon_version = data.aws_eks_addon_version.kube-proxy[count.index].version
  lifecycle {
    ignore_changes = [addon_version]
  }
}

## 1. eks_pod_identity_agent: latest
data "aws_eks_addon_version" "eks_pod_identity_agent" {
  count              = var.cluster_settings == null || var.node_settings == null ? 0 : var.cluster_settings.addons.eks_pod_identity_agent == false ? 0 : 1
  addon_name         = "eks-pod-identity-agent"
  kubernetes_version = aws_eks_cluster.cluster[count.index].version
  most_recent        = true
}
resource "aws_eks_addon" "eks_pod_identity_agent" {
  count         = var.cluster_settings == null || var.node_settings == null ? 0 : var.cluster_settings.addons.eks_pod_identity_agent == false ? 0 : 1
  cluster_name  = aws_eks_cluster.cluster[count.index].name
  addon_name    = "eks-pod-identity-agent"
  addon_version = data.aws_eks_addon_version.eks_pod_identity_agent[count.index].version
  depends_on = [
    aws_eks_cluster.cluster
  ]
  lifecycle {
    ignore_changes = [addon_version]
  }
}

## 5. snapshot-controller: latest
data "aws_eks_addon_version" "snapshot-controller" {
  count              = var.cluster_settings == null || var.node_settings == null ? 0 : var.cluster_settings.addons.snapshot_controller ? 1 : 0
  addon_name         = "snapshot-controller"
  kubernetes_version = aws_eks_cluster.cluster[count.index].version
  most_recent        = true
}
resource "aws_eks_addon" "snapshot-controller" {
  count         = var.cluster_settings == null || var.node_settings == null ? 0 : var.cluster_settings.addons.snapshot_controller ? 1 : 0
  cluster_name  = aws_eks_cluster.cluster[count.index].name
  addon_name    = "snapshot-controller"
  addon_version = data.aws_eks_addon_version.snapshot-controller[count.index].version
  depends_on = [
    aws_eks_addon.eks_pod_identity_agent,
    aws_eks_cluster.cluster,
    aws_eks_node_group.node
  ]
  lifecycle {
    ignore_changes = [addon_version]
  }
}

## 6. aws_guardduty_agent: latest
data "aws_eks_addon_version" "aws_guardduty_agent" {
  count              = var.cluster_settings == null || var.node_settings == null ? 0 : var.cluster_settings.addons.aws_guardduty_agent ? 1 : 0
  addon_name         = "aws-guardduty-agent"
  kubernetes_version = aws_eks_cluster.cluster[count.index].version
  most_recent        = true
}
resource "aws_eks_addon" "aws_guardduty_agent" {
  count         = var.cluster_settings == null || var.node_settings == null ? 0 : var.cluster_settings.addons.aws_guardduty_agent ? 1 : 0
  cluster_name  = aws_eks_cluster.cluster[count.index].name
  addon_name    = "aws-guardduty-agent"
  addon_version = data.aws_eks_addon_version.aws_guardduty_agent[count.index].version
  depends_on = [
    aws_eks_addon.eks_pod_identity_agent,
    aws_eks_cluster.cluster,
    aws_eks_node_group.node
  ]
  lifecycle {
    ignore_changes = [addon_version]
  }
}

## 7. amazon_cloudwatch_observability: latest
data "aws_eks_addon_version" "amazon_cloudwatch_observability" {
  count              = var.cluster_settings == null || var.node_settings == null ? 0 : var.cluster_settings.addons.amazon_cloudwatch_observability ? 1 : 0
  addon_name         = "amazon-cloudwatch-observability"
  kubernetes_version = aws_eks_cluster.cluster[count.index].version
  most_recent        = true
}
resource "aws_eks_addon" "amazon_cloudwatch_observability" {
  count         = var.cluster_settings == null || var.node_settings == null ? 0 : var.cluster_settings.addons.amazon_cloudwatch_observability ? 1 : 0
  cluster_name  = aws_eks_cluster.cluster[count.index].name
  addon_name    = "amazon-cloudwatch-observability"
  addon_version = data.aws_eks_addon_version.amazon_cloudwatch_observability[count.index].version
  depends_on = [
    aws_eks_addon.eks_pod_identity_agent,
    aws_eks_cluster.cluster,
    aws_eks_node_group.node
  ]
  lifecycle {
    ignore_changes = [addon_version]
  }
}
resource "aws_eks_pod_identity_association" "cloudwatch" {
  count           = var.cluster_settings == null || var.node_settings == null ? 0 : var.cluster_settings.addons.amazon_cloudwatch_observability ? 1 : 0
  cluster_name    = aws_eks_cluster.cluster[count.index].name
  namespace       = "amazon-cloudwatch"
  service_account = "cloudwatch-agent"
  role_arn        = aws_iam_role.amazon_cloudwatch_observability[count.index].arn

  depends_on = [
    aws_eks_addon.eks_pod_identity_agent,
    aws_eks_cluster.cluster,
    aws_eks_node_group.node
  ]
}


