# Security groups:
output "security_group_ids" {
  value = {for k, v in aws_security_group.cluster : k => v.id} #data.aws_security_groups.cluster.id
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

output "public_route_table_id" {
  value = aws_route_table.public[0].id # Replace with the actual resource type
}

output "private_route_table_id" {
  value = aws_route_table.public[0].id # Replace with the actual resource type
}