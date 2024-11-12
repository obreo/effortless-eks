# Security groups:
output "cluster_security_group_id" {
  value = aws_security_group.cluster[0].id #data.aws_security_groups.cluster.id
}
output "public_subnet_cidr_blocks" {
  value = aws_subnet.public[*].id # Replace with the actual resource type in your VPC module
}

output "private_subnet_cidr_blocks" {
  value = aws_subnet.private[*].id # Replace with the actual resource type
}

output "vpc_id" {
  value = aws_vpc.vpc.id # Replace with the actual resource type
}
