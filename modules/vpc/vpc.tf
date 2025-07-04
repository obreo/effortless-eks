# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = try(var.vpc_settings.vpc_cidr_block, "")
  assign_generated_ipv6_cidr_block = var.vpc_settings.enable_aws_ipv6_cidr_block.ipv6_native == true || var.vpc_settings.enable_aws_ipv6_cidr_block.public_cidr_count_prefix64 != 0 || var.vpc_settings.enable_aws_ipv6_cidr_block.private_cidr_count_prefix64 != 0 ? true : false
  enable_dns_support   = true
  enable_dns_hostnames = try(var.vpc_settings.enable_dns_hostnames != {} ? true: false)
  tags = {
    Name = var.name
  }
}

# SUBNET
resource "aws_subnet" "public" {
  count                                           = var.vpc_settings.enable_aws_ipv6_cidr_block.ipv6_native ? var.vpc_settings.enable_aws_ipv6_cidr_block.public_cidr_count_prefix64 : length(var.vpc_settings.public_subnet_cidr_blocks)
  vpc_id                                          = aws_vpc.vpc.id
  cidr_block                                      = var.vpc_settings.enable_aws_ipv6_cidr_block.ipv6_native || length(var.vpc_settings.public_subnet_cidr_blocks) == 0 ? null : var.vpc_settings.public_subnet_cidr_blocks[count.index]
  ipv6_cidr_block                                 = try(var.vpc_settings.enable_aws_ipv6_cidr_block.public_cidr_count_prefix64 != 0 ? cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, count.index) : null)
  availability_zone                               = try(var.vpc_settings.availability_zones[count.index % length(var.vpc_settings.availability_zones)], null)
  enable_resource_name_dns_a_record_on_launch     = var.vpc_settings.enable_aws_ipv6_cidr_block.ipv6_native || length(var.vpc_settings.private_subnet_cidr_blocks) == 0 ? false : true
  map_public_ip_on_launch                         = true
  enable_resource_name_dns_aaaa_record_on_launch  = var.vpc_settings.enable_aws_ipv6_cidr_block != {} ? true : false
  ipv6_native                                     = length(var.vpc_settings.public_subnet_cidr_blocks) == 0 ? true : var.vpc_settings.enable_aws_ipv6_cidr_block.ipv6_native ? true : false
  tags = merge(
    {
      Name = "${var.name}-public"
    },
    var.vpc_settings.include_eks_tags             != null ? { "kubernetes.io/role/elb" = "1" } : {},
    var.vpc_settings.include_eks_tags             != null ? (var.vpc_settings.include_eks_tags.cluster_name != null ? { "kubernetes.io/cluster/${var.vpc_settings.include_eks_tags.cluster_name}" = "${var.vpc_settings.include_eks_tags.shared_or_owned}" } : {}) : {}
  )
  lifecycle {
    ignore_changes                                = [map_public_ip_on_launch]
  }
}
resource "aws_subnet" "private" {
  count                                           = var.vpc_settings.enable_aws_ipv6_cidr_block.ipv6_native || var.vpc_settings.enable_aws_ipv6_cidr_block.private_cidr_count_prefix64 != 0 ? var.vpc_settings.enable_aws_ipv6_cidr_block.private_cidr_count_prefix64 : length(var.vpc_settings.private_subnet_cidr_blocks)
  vpc_id                                          = aws_vpc.vpc.id
  cidr_block                                      = var.vpc_settings.enable_aws_ipv6_cidr_block.ipv6_native || length(var.vpc_settings.private_subnet_cidr_blocks) == 0 ? null : var.vpc_settings.private_subnet_cidr_blocks[count.index]
  ipv6_cidr_block                                 = try(var.vpc_settings.enable_aws_ipv6_cidr_block.private_cidr_count_prefix64 != 0 ? cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, var.vpc_settings.enable_aws_ipv6_cidr_block.public_cidr_count_prefix64 + count.index) : null)
  assign_ipv6_address_on_creation                 = var.vpc_settings.enable_aws_ipv6_cidr_block.ipv6_native || var.vpc_settings.enable_aws_ipv6_cidr_block.private_cidr_count_prefix64 != 0 ? true : false
  availability_zone                               = try(var.vpc_settings.availability_zones[count.index % length(var.vpc_settings.availability_zones)], null)
  enable_resource_name_dns_a_record_on_launch     = var.vpc_settings.enable_aws_ipv6_cidr_block.ipv6_native || length(var.vpc_settings.private_subnet_cidr_blocks) == 0 ? false : true
  enable_resource_name_dns_aaaa_record_on_launch  = var.vpc_settings.enable_aws_ipv6_cidr_block != {} ? true : false
  map_public_ip_on_launch                         = false
  ipv6_native                                     = length(var.vpc_settings.private_subnet_cidr_blocks) == 0 ? true : var.vpc_settings.enable_aws_ipv6_cidr_block.ipv6_native ? true : false
  tags = merge(
    {
      Name = "${var.name}-private"
    },
    var.vpc_settings.include_eks_tags             != null ? { "kubernetes.io/role/internal-elb" = "1" } : {},
    var.vpc_settings.include_eks_tags             != null ? (var.vpc_settings.include_eks_tags.cluster_name != null ? { "kubernetes.io/cluster/${var.vpc_settings.include_eks_tags.cluster_name}" = "${var.vpc_settings.include_eks_tags.shared_or_owned}" } : {}) : {}
  )
  lifecycle {
    ignore_changes                                = [map_public_ip_on_launch]
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

resource "aws_egress_only_internet_gateway" "egw" {
  count = var.vpc_settings.enable_aws_ipv6_cidr_block != null ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name}-egw"
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
    ignore_changes = [allocation_id]
  }
}

# ELASTIC IP
resource "aws_eip" "one" {
  count  = var.vpc_settings.private_subnet_cidr_blocks == null ? 0 : var.vpc_settings.create_private_subnets_nat ? 1 : 0
  domain = "vpc"
}


# ROUTE TABLE
resource "aws_route_table" "public" {
  count  = var.vpc_settings.public_subnet_cidr_blocks != null || var.vpc_settings.enable_aws_ipv6_cidr_block.ipv6_native ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  dynamic "route" {
    for_each = var.vpc_settings.public_subnet_cidr_blocks != null ? [1] : []
    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw[count.index].id
    }
  }

  dynamic "route" {
    for_each = var.vpc_settings.enable_aws_ipv6_cidr_block.ipv6_native || var.vpc_settings.enable_aws_ipv6_cidr_block.public_cidr_count_prefix64 != 0 ? [1] : []
    content {
      ipv6_cidr_block  = "::/0"
      gateway_id = aws_egress_only_internet_gateway.egw[count.index].id
    }
  }

  tags = {
    Name = "${var.name}-public"
  }

    lifecycle {
      ignore_changes = [route]
    }
}
resource "aws_route_table_association" "public" {
  count          = (
    var.vpc_settings.enable_aws_ipv6_cidr_block.ipv6_native
    || var.vpc_settings.enable_aws_ipv6_cidr_block.public_cidr_count_prefix64 != 0
  ) ? max(
    var.vpc_settings.enable_aws_ipv6_cidr_block.public_cidr_count_prefix64,
    try(length(var.vpc_settings.public_subnet_cidr_blocks), 0),
  ) : length(var.vpc_settings.public_subnet_cidr_blocks)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  count  = var.vpc_settings.private_subnet_cidr_blocks != null || var.vpc_settings.enable_aws_ipv6_cidr_block.private_cidr_count_prefix64 != 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  dynamic "route" {
  for_each = var.vpc_settings.enable_aws_ipv6_cidr_block.private_cidr_count_prefix64 != null ? [1] : []
    content {
      ipv6_cidr_block         = "::/0"
      gateway_id = aws_egress_only_internet_gateway.egw[count.index].id
    }
  }

  dynamic "route" {
    for_each = var.vpc_settings.private_subnet_cidr_blocks != null && var.vpc_settings.create_private_subnets_nat ? [1] : []
    content {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public[count.index].id
    }
  }

  tags = {
    Name = "${var.name}-private"
  }

  #lifecycle {
    #ignore_changes = [route]
  #}
}

resource "aws_route_table_association" "private" {
  count = (
    var.vpc_settings.enable_aws_ipv6_cidr_block.ipv6_native
    || var.vpc_settings.enable_aws_ipv6_cidr_block.private_cidr_count_prefix64 != 0
  ) ? max(
    var.vpc_settings.enable_aws_ipv6_cidr_block.private_cidr_count_prefix64,
    try(length(var.vpc_settings.private_subnet_cidr_blocks), 0)
  ) : length(var.vpc_settings.private_subnet_cidr_blocks)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}


# SECURITY GROUP
resource "aws_security_group" "cluster" {
  #count       = var.security_groups == null ? 0 : length(var.vpc_settings.vpc_cidr_block) > 0 && var.security_groups != null ? 1 : 0
  for_each = var.security_groups
  name        = each.value.name != null ? each.value.name : "${var.name}-cluster"
  description = each.value.description != null ? each.value.description : "Allows ports to ${var.name}"
  vpc_id      = aws_vpc.vpc.id

  tags = each.value.tags != null ? each.value.tags : {
    Application = "${var.name}"
    Purpose     = "eks-cluster-access-restricted-${var.name}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "dynamic_ingress" {
  for_each = {
    for idx, item in flatten([
      for sg_key, sg_value in var.security_groups : [
        for port in sg_value.inbound.ports : {
          sg_key       = sg_key
          port         = port
          ip_protocol = try(sg_value.inbound.ip_protocol, "tcp")
          destination = try(sg_value.inbound.destination, {
            cidr_ipv4      = null
            cidr_ipv6      = null
            security_group = null
            prefix_list_id = null
          })
          description = try(sg_value.inbound.rule_description, "Allows ports to ${var.name}")
        }
      ]
    ]) : "${item.sg_key}-${item.port}" => item
  }

    security_group_id            = aws_security_group.cluster[each.value.sg_key].id
    ip_protocol                  = each.value.ip_protocol # try(var.vpc_settings.security_group.ip_protocol, "tcp")
    from_port                    = each.value.port # try(var.vpc_settings.security_group.ports[count.index], 0)
    to_port                      = each.value.port # try(var.vpc_settings.security_group.ports[count.index], 0)
    cidr_ipv4                    = each.value.destination.cidr_ipv4 # var.vpc_settings.security_group.source.cidr_ipv4 != null ? var.vpc_settings.security_group.source.cidr_ipv4 : null
    cidr_ipv6                    = each.value.destination.cidr_ipv6 # var.vpc_settings.security_group.source.cidr_ipv6 != null ? var.vpc_settings.security_group.source.cidr_ipv6 : null
    referenced_security_group_id = try(aws_security_group.cluster[each.value.destination.security_group].id,each.value.destination.security_group) # each.value.destination.security_group # var.vpc_settings.security_group.source.security_group != null ? var.vpc_settings.security_group.source.security_group : aws_security_group.cluster[count.index].id
    prefix_list_id               = each.value.destination.prefix_list_id # var.vpc_settings.security_group.source.prefix_list_id != null ? var.vpc_settings.security_group.source.prefix_list_id : null
}


resource "aws_vpc_security_group_egress_rule" "cluster" {
  for_each = var.security_groups
  security_group_id = aws_security_group.cluster[each.key].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "cluster_ipv6" {
  for_each = var.security_groups
  security_group_id = aws_security_group.cluster[each.key].id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# INTERFACE VPC ENDPOINT
resource "aws_vpc_endpoint" "interface" {
  for_each = var.interface_endpoints

  vpc_id            = aws_vpc.vpc.id
  service_name      = each.value.service
  vpc_endpoint_type = "Interface"
  subnet_ids        = each.value.subnet_ids != null ? each.value.subnet_ids : aws_subnet.private[*].id
  private_dns_enabled = lookup(each.value, "private_dns", true)
  security_group_ids  = each.value.security_groups
  auto_accept = true
  ip_address_type = each.value.connection_ip_type
  dns_options {
    dns_record_ip_type = each.value.dns_record_ip_type != null ? each.value.dns_record_ip_type : lookup(
      {
        ipv4      = "ipv4"
        ipv6      = "ipv6"
        dualstack = "dualstack"
      },
      each.value.connection_ip_type,
      "ipv4"
    )
  }
  tags = {
    Name = "endpoint-${replace(each.value.service, ".", "-")}"
  }
}
