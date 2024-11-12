variable "metadata" {
  type = object({
    name        = string
    environment = string
    eks_version = string
    region      = optional(string)
  })
}

variable "cluster_settings" {
  type = object({
    cluster_subnet_ids                       = list(string)                 # Required: Minimum are two, in different AZs
    allowed_cidrs_to_access_cluster_publicly = optional(list(string))       # Optional, set default to an empty list. 
    set_custom_pod_cidr_block                = optional(string)             # Optional, default to null. # Should be: Private IP block, Doesn't overlap with VPC Subnets but within VPC CIDR, Between /24 and /12 subnet. | Can not be chnaged modified.
    support_type                             = optional(string, "STANDARD") # Default value is "STANDARD"
    ip_family                                = optional(string, "ipv4")
    security_group_ids                       = optional(list(string))
    enable_endpoint_public_access            = optional(bool, true)  # Default to true
    enable_endpoint_private_access           = optional(bool, false) # Default to false
    create_eks_admin_access_iam_group        = optional(bool, false)
    create_eks_custom_access_iam_group       = optional(bool, false)

    enable_logging = optional(object({
      api               = optional(bool, false) # Default to false
      audit             = optional(bool, false) # Default to false
      authenticator     = optional(bool, false) # Default to false
      controllerManager = optional(bool, false) # Default to false
      scheduler         = optional(bool, false) # Default to true
    }))

    addons = optional(object({
      vpc_cni                         = optional(bool, false)
      eks_pod_identity_agent          = optional(bool, true)
      snapshot_controller             = optional(bool, false)
      aws_guardduty_agent             = optional(bool, false)
      amazon_cloudwatch_observability = optional(bool, false)
      aws_ebs_csi_driver = optional(object({
        fstype    = optional(string, "ext4")
        ebs_type  = optional(string, "gp3")
        iopsPerGB = optional(number)
        encrypted = optional(bool, true)
      }))
      aws_efs_csi_driver = optional(object({
        enable          = optional(bool, false)
        encrypted       = optional(bool, true)
        subnet_ids      = optional(list(string))
        efs_resource_id = optional(string, "")
      }))
      aws_mountpoint_s3_csi_driver = optional(object({
        enable        = optional(bool, false)
        s3_bucket_arn = optional(string, "")
      }))
    }))
  })

  default = null
}

variable "node_settings" {
  type = object({
    cluster_name          = optional(string)
    node_group_name       = optional(string)
    workernode_subnet_ids = list(string)
    taints                = optional(list(map(string)))
    labels                = optional(map(string))
    capacity_config = object({
      capacity_type  = optional(string, "ON_DEMAND")
      instance_types = list(string)
      disk_size      = optional(number, 20)
    })
    scaling_config = optional(object({
      desired         = optional(number, 1)
      max_size        = optional(number, 1)
      min_size        = optional(number, 1)
      max_unavailable = optional(number, 1)
    }))
    remote_access = optional(object({
      enable                  = optional(bool, false)
      ssh_key_name            = optional(string)
      allowed_security_groups = optional(list(string))
    }))
  })

  # Add default values here instead of in the type definition
  default = null
}


variable "fargate_profile" {
  type = object({
    cluster_name         = optional(string)
    subnet_ids           = list(string)
    fargate_profile_name = optional(string)
    namespace            = optional(string, "fargate-space")
  })
  # Add default values here instead of in the type definition
  default = null
}


variable "plugins" {
  type = object({
    create_ecr_registry = optional(bool, false)
    dont_wait           = optional(bool, true)
    cluster_autoscaler = optional(object({
      values = optional(list(string), [])
    }))
    metrics_server = optional(object({
      values = optional(list(string), [])
    }))
    nginx_controller = optional(object({
      scheme_type       = optional(string, "internet-facing") # OR "internal"
      enable_cross_zone = optional(bool, false)
      values            = optional(list(string), [])
    }))
    aws_alb_controller = optional(object({
      vpc_id = optional(string)
      values = optional(list(string), [])
    }))
    argo_cd = optional(object({
      values = optional(list(string), [])
    }))
    external_secrets = optional(object({
      values = optional(list(string), [])
    }))
    secrets_store_csi_driver = optional(object({
      values = optional(list(string), [])
    }))
    loki = optional(object({
      values = optional(list(string), [])
    }))
    prometheus = optional(object({
      values = optional(list(string), [])
    }))
    cert_manager = optional(object({
      values = optional(list(string), [])
    }))
    kubernetes_dashboard = optional(object({
      hosts          = optional(list(string))
      use_internally = optional(bool, false)
      values         = optional(list(string), [])
    }))
    rancher = optional(object({ # Depends on certbot 
      host                 = optional(string)
      use_internal_ingress = optional(bool, false)
      values               = optional(list(string), [])
    }))
    calico_cni = optional(object({
      enable = optional(bool, false)
      cidr   = optional(string)
      values = optional(list(string))

    }))
  })
  default = null
}
