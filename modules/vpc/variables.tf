
variable "name" {
  type = string
}
variable "vpc_settings" {
  type = object({
    vpc_cidr_block             = string
    public_subnet_cidr_blocks  = optional(list(string),[])
    private_subnet_cidr_blocks = optional(list(string),[])
    create_private_subnets_nat = optional(bool, true)
    availability_zones         = optional(list(string))
    enable_dns_hostnames        = optional(bool, true)

    include_eks_tags = optional(object({
      cluster_name    = optional(string)
      shared_or_owned = optional(string, "owned")
    }))

    enable_aws_ipv6_cidr_block = optional(object({
      public_cidr_count_prefix64 = optional(number, 0)
      private_cidr_count_prefix64 = optional(number, 0)
      ipv6_native  = optional(bool, false)

    }))

  })
}
    # Security Group
variable "security_groups" {
  type = map(object({
    name        = optional(string)
    description = optional(string)
    tags       = optional(map(string))

    inbound = optional(object({
      rule_description = optional(string)
      ports = optional(list(number)) # The ports to allow inbound traffic
      ip_protocol = optional(string, "tcp") # The protocol to allow (e.g., tcp, udp)
      destination = optional(object({
          cidr_ipv4      = optional(string)
          cidr_ipv6      = optional(string)
          security_group = optional(string)
          prefix_list_id = optional(string)
      }))     

      #enable_ssh_inbound = optional(object({
      #  cidr_ipv4 = optional(string)
      #  cidr_ipv6      = optional(string)
      #  security_group = optional(string)
      #  prefix_list_id = optional(string)
      #}))
    }))
  }))
}

variable "interface_endpoints" {
  description = "Map of interface endpoint services to enable"
  type = map(object({
    service         = string        # e.g., com.amazonaws.us-east-1.ssm
    private_dns     = optional(bool, true)
    security_groups = optional(list(string), [])  # Allow passing SGs
    subnet_ids      = optional(list(string))      # Optional override
    connection_ip_type = optional(string, "ipv4")
    dns_record_ip_type = optional(string)
  }))
  default = {}
}
