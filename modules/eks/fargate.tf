resource "aws_eks_fargate_profile" "eks" {
  count                  = var.fargate_profile != null ? 1 : 0
  cluster_name           = var.fargate_profile.cluster_name != null ? var.fargate_profile.cluster_name : "${var.metadata.name}-default-cluster"
  fargate_profile_name   = var.fargate_profile.fargate_profile_name != null ? var.fargate_profile.fargate_profile_name : "${var.metadata.name}-fargate-profile"
  pod_execution_role_arn = aws_iam_role.fargate[count.index].arn
  subnet_ids             = var.fargate_profile.subnet_ids

  selector {
    namespace = var.fargate_profile.namespace != null ? var.fargate_profile.namespace : "fargate-space"
  }

  depends_on = [
    aws_eks_cluster.cluster,
    aws_eks_node_group.node,
  aws_eks_addon.kube-proxy]
}
###################################################################################
# ROLE
###################################################################################
resource "aws_iam_role" "fargate" {
  count = var.fargate_profile != null ? 1 : 0
  name  = "eks-fargate-profile-example"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  depends_on = [
    aws_eks_cluster.cluster,
    aws_eks_node_group.node,
  aws_eks_addon.kube-proxy]
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSFargatePodExecutionRolePolicy" {
  count      = var.fargate_profile != null ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate[count.index].name
  depends_on = [
    aws_eks_cluster.cluster,
    aws_eks_node_group.node,
  aws_eks_addon.kube-proxy]
}