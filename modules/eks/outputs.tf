# EKS
output "endpoint" {
  value = aws_eks_cluster.cluster[*].endpoint
}
output "kubeconfig_certificate_authority_data" {
  value = var.cluster_settings != null ? aws_eks_cluster.cluster[0].certificate_authority[0].data : ""
}

output "cluster_id" {
  value = aws_eks_cluster.cluster[*].id
}
output "cluster_name" {
  value = var.cluster_settings != null ? aws_eks_cluster.cluster[0].name : ""
}


### Based on data resource:
# certificate
output "aws_eks_cluster_certificate_data" {
  value = data.aws_eks_cluster.cluster.certificate_authority[0].data
}
# endpoint
output "aws_eks_cluster_data" {
  value = data.aws_eks_cluster.cluster.endpoint
}
# name
output "aws_eks_cluster_name" {
  value = data.aws_eks_cluster.cluster.name
}
data "aws_eks_cluster" "cluster" {
  name       = aws_eks_cluster.cluster[0].name
  depends_on = [aws_eks_cluster.cluster]
}

# token
output "aws_eks_cluster_auth" {
  value = data.aws_eks_cluster_auth.cluster.token

}
data "aws_eks_cluster_auth" "cluster" {
  name       = aws_eks_cluster.cluster[0].name
  depends_on = [aws_eks_cluster.cluster]
}

