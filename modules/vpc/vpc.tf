# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_settings.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.name
  }
}

# SUBNET
resource "aws_subnet" "public" {
  count = var.vpc_settings.public_subnet_cidr_blocks != null ? length(var.vpc_settings.public_subnet_cidr_blocks) : 0 # Dynamically creates subnets based on number of CIDR blocks

  vpc_id                                      = aws_vpc.vpc.id
  cidr_block                                  = try(var.vpc_settings.public_subnet_cidr_blocks[count.index], [""])
  availability_zone                           = try(var.vpc_settings.availability_zones[count.index % length(var.vpc_settings.availability_zones)], [""])
  enable_resource_name_dns_a_record_on_launch = true
  map_public_ip_on_launch                     = true
  tags = merge(
    {
      Name = "${var.name}-public"
    },
    var.vpc_settings.include_eks_tags != null ? { "kubernetes.io/role/elb" = "1" } : {},
    var.vpc_settings.include_eks_tags != null ? (var.vpc_settings.include_eks_tags.cluster_name != null ? { "kubernetes.io/cluster/${var.vpc_settings.include_eks_tags.cluster_name}" = "${var.vpc_settings.include_eks_tags.shared_or_owned}" } : {}) : {}
  )
  lifecycle {
    ignore_changes = [map_public_ip_on_launch]
  }
}
resource "aws_subnet" "private" {
  count                                       = var.vpc_settings.private_subnet_cidr_blocks != null ? length(var.vpc_settings.private_subnet_cidr_blocks) : 0 # Dynamically creates subnets based on number of CIDR blocks
  vpc_id                                      = aws_vpc.vpc.id
  cidr_block                                  = try(var.vpc_settings.private_subnet_cidr_blocks[count.index], [""])
  availability_zone                           = try(var.vpc_settings.availability_zones[count.index], [""])
  enable_resource_name_dns_a_record_on_launch = true
  map_public_ip_on_launch                     = false
  tags = merge(
    {
      Name = "${var.name}-private"
    },
    var.vpc_settings.include_eks_tags != null ? { "kubernetes.io/role/internal-elb" = "1" } : {},
    var.vpc_settings.include_eks_tags != null ? (var.vpc_settings.include_eks_tags.cluster_name != null ? { "kubernetes.io/cluster/${var.vpc_settings.include_eks_tags.cluster_name}" = "${var.vpc_settings.include_eks_tags.shared_or_owned}" } : {}) : {}
  )
  lifecycle {
    ignore_changes = [map_public_ip_on_launch]
  }
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "gw" {
  count  = length(var.vpc_settings.vpc_cidr_block) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name}-ig"
  }
}


# NAT GATEWAY
resource "aws_nat_gateway" "public" {
  count         = var.vpc_settings.private_subnet_cidr_blocks == null ? 0 : var.vpc_settings.create_private_subnets_nat ? 1 : 0
  allocation_id = aws_eip.one[count.index].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.name}-NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw[0]]

  lifecycle {
    ignore_changes = [allocation_id, public_ip]
  }
}

# ELASTIC IP
resource "aws_eip" "one" {
  count  = var.vpc_settings.private_subnet_cidr_blocks == null ? 0 : var.vpc_settings.create_private_subnets_nat ? 1 : 0
  domain = "vpc"
}


# ROUTE TABLE
resource "aws_route_table" "public" {
  count  = var.vpc_settings.public_subnet_cidr_blocks != null ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw[count.index].id
  }

  tags = {
    Name = "${var.name}-public"
  }
}
resource "aws_route_table_association" "public" {
  count          = var.vpc_settings.public_subnet_cidr_blocks != null ? length(var.vpc_settings.public_subnet_cidr_blocks) : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}


resource "aws_route_table" "private" {
  count  = var.vpc_settings.private_subnet_cidr_blocks == null ? 0 : var.vpc_settings.create_private_subnets_nat ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public[count.index].id
  }

  tags = {
    Name = "${var.name}-private"
  }

  lifecycle {
    ignore_changes = [route]
  }
}

resource "aws_route_table_association" "private" {
  count          = var.vpc_settings.private_subnet_cidr_blocks == null ? 0 : var.vpc_settings.create_private_subnets_nat ? length(var.vpc_settings.private_subnet_cidr_blocks) : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}



# SECURITY GROUP
resource "aws_security_group" "cluster" {
  count       = var.vpc_settings.security_group == null ? 0 : length(var.vpc_settings.vpc_cidr_block) > 0 ? 1 : 0
  name        = var.name
  description = "Allows ports to ${var.name}"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Application = "${var.name}"
    Purpose     = "eks-cluster-access-restricted-${var.name}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "dynamic_ingress" {
  count                        = var.vpc_settings.security_group.ports == null ? 0 : length(var.vpc_settings.vpc_cidr_block) > 0 ? length(var.vpc_settings.security_group.ports) : 0
  security_group_id            = aws_security_group.cluster[count.index].id
  ip_protocol                  = try(var.vpc_settings.security_group.ip_protocol, "tcp")
  from_port                    = try(var.vpc_settings.security_group.ports[count.index], 0)
  to_port                      = try(var.vpc_settings.security_group.ports[count.index], 0)
  cidr_ipv4                    = var.vpc_settings.security_group.source.cidr_ipv4 != null ? var.vpc_settings.security_group.source.cidr_ipv4 : null
  cidr_ipv6                    = var.vpc_settings.security_group.source.cidr_ipv6 != null ? var.vpc_settings.security_group.source.cidr_ipv6 : null
  referenced_security_group_id = var.vpc_settings.security_group.source.security_group != null ? var.vpc_settings.security_group.source.security_group : aws_security_group.cluster[count.index].id
  prefix_list_id               = var.vpc_settings.security_group.source.prefix_list_id != null ? var.vpc_settings.security_group.source.prefix_list_id : null

}
resource "aws_vpc_security_group_ingress_rule" "ssh_node" {
  count             = var.vpc_settings.security_group.ssh_port.cidr_ipv4 == null ? 0 : length(var.vpc_settings.vpc_cidr_block) > 0 ? 1 : 0
  security_group_id = aws_security_group.cluster[count.index].id
  cidr_ipv4         = try(var.vpc_settings.security_group.ssh_port.cidr_ipv4, "0.0.0.0/0")
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
# Outbound
resource "aws_vpc_security_group_egress_rule" "cluster" {
  count             = var.vpc_settings.security_group == null ? 0 : length(var.vpc_settings.vpc_cidr_block) > 0 ? 1 : 0
  security_group_id = aws_security_group.cluster[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
