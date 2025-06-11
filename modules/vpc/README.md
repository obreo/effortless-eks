# How To Use

```


module "vpc" {
  source = "./modules/vpc"
  name   = var.metadata.name
  vpc_settings = {
    vpc_cidr_block             = string
    public_subnet_cidr_blocks  = list(string) # Optional if private subnet cidr created
    private_subnet_cidr_blocks = list(string) # Optional if public subnet cidr created
    create_private_subnets_nat = bool # Optional, defaults to true
    availability_zones         = list(string)
    enable_dns_hostnames       = bool # defaults to true

    include_eks_tags = { # Optional, Required for EKS cluster.
      cluster_name    = string
      shared_or_owned = string # Defaults to "owned"
    }

    enable_aws_ipv6_cidr_block = {
      public_cidr_count_prefix64 = Number
      private_cidr_count_prefix64 = Number
      ipv6_native  = bool # defaults to false
    }
  }
  security_groups = {
    # Key(security group name) = Value (specifications)
    "security_group_1" = {
      name        = optional(string)
      description = optional(string)
      tags       = optional(map(string))

      inbound = {
        rule_description = optional(string)
        ports = optional(list(number)) # The ports to allow inbound traffic
        ip_protocol = optional(string, "tcp") # The protocol to allow (e.g., tcp, udp)
        destination = {
            cidr_ipv4      = optional(string)
            cidr_ipv6      = optional(string)
            security_group = optional(string)
            prefix_list_id = optional(string)
        }
      }
    }

    "security_group_2" = {
      name        = optional(string)
      description = optional(string)
      tags       = optional(map(string))

      inbound = {
        rule_description = optional(string)
        ports = optional(list(number)) # The ports to allow inbound traffic
        ip_protocol = optional(string, "tcp") # The protocol to allow (e.g., tcp, udp)
        destination = {
            cidr_ipv4      = optional(string)
            cidr_ipv6      = optional(string)
            security_group = optional(string)
            prefix_list_id = optional(string)
        }
      }
    }
  }
}
```

# OUTPUTS

## VPC

```
# SECURITY GROUPS:
cluster_security_group_id

# SUBNETS
public_subnet_cidr_blocks
private_subnet_cidr_blocks

# VPC ID
vpc_id
```
