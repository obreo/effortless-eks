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
    create_eks_custom_access_iam_group       = optional(list(string), []) # Default to an empty list, else fill with EKS policies names. e.g "eks:listClusters"

    enable_logging = optional(object({
      api               = optional(bool, false) # Default to false
      audit             = optional(bool, false) # Default to false
      authenticator     = optional(bool, false) # Default to false
      controllerManager = optional(bool, false) # Default to false
      scheduler         = optional(bool, false) # Default to false
      retention_in_days = optional(number, 3) # Default to 3 days
    }))

    addons = optional(object({
      vpc_cni                         = optional(bool, true)
      eks_pod_identity_agent          = optional(bool, true)
      snapshot_controller             = optional(bool, false)
      aws_guardduty_agent             = optional(bool, false)
      amazon_cloudwatch_observability = optional(bool, false)
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