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
    security_group = { # Optional
      ports       = list(number)
      ip_protocol = string # Defaults to "tcp", for all ports "-1"
      source = { # Only one source is allowed.
        cidr_ipv4   = string
        cidr_ipv6   = string
        security_group   = string
        prefix_list_id   = string
      }
      ssh_port = { # Optional, creates port 22 rule for the cidr specified.
        cidr_ipv4 = string # Defaults to "0.0.0.0/0"
      }
    }
    include_eks_tags = { # Optional, Required for EKS cluster.
      cluster_name    = string
      shared_or_owned = string # Defaults to "owned"
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