
variable "name" {
  type = string
}
variable "vpc_settings" {
  type = object({
    vpc_cidr_block             = string
    public_subnet_cidr_blocks  = optional(list(string))
    private_subnet_cidr_blocks = optional(list(string))
    create_private_subnets_nat = optional(bool, true)
    availability_zones         = optional(list(string))
    security_group = optional(object({
      ports       = optional(list(number))
      ip_protocol = optional(string, "tcp")
      source = optional(object({
        cidr_ipv4      = optional(string)
        cidr_ipv6      = optional(string)
        security_group = optional(string)
        prefix_list_id = optional(string)
      }))
      ssh_port = optional(object({
        cidr_ipv4 = optional(string)
      }))
    }))
    include_eks_tags = optional(object({
      cluster_name    = optional(string)
      shared_or_owned = optional(string, "owned")
    }))
  })
}