output "cluster_name" {
  value = module.eks.cluster_name
}

output "endpoint" {
  value = module.eks.aws_eks_cluster_data
}
