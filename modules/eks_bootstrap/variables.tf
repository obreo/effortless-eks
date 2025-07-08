variable "integrations" {
  type = object({
      cluster_name = optional(string, "")
      aws_ebs_csi_driver = optional(object({
        fstype    = optional(string, "ext4")
        ebs_type  = optional(string, "gp3")
        iopsPerGB = optional(number)
        encrypted = optional(bool, true)
      }))

      aws_efs_csi_driver = optional(object({
        name            = optional(string, "")
        encrypted       = optional(bool, true)
        subnet_ids      = optional(list(string))
        efs_resource_id = optional(string, "")
        security_groups = optional(list(string), [])
      }))

      aws_mountpoint_s3_csi_driver = optional(object({
        name            = optional(string, "")
        s3_bucket_arn = optional(string, "") # Default to empty string, if not set, it will create a new bucket
        create_vpc_endpoint = optional(object({
          vpc_id = optional(string, "")
          route_table_ids=optional(list(string), []) # Default to all route tables in vpc
          bucket_region = optional(string, "") 
        }))
      }))

      ecr_registry = optional(object({
        name = optional(string, "")
      }))
  })

  default = null
}


variable "plugins" {
  type = object({

    dont_wait_for_helm_install = optional(bool, true)
    cluster_autoscaler = optional(object({
      cluster_name = optional(string)
      region = optional(string, "")
      values = optional(list(string), [])
    }))

    metrics_server = optional(object({
      values = optional(list(string), [])
    }))

    nginx_controller = optional(map(object({
      scheme_type       = optional(string, "internet-facing") # OR "internal"
      alb_config = optional(object({
        alb_ingress_traffic_mode = optional(string, "ip")
        alb_family_type         = optional(string, "IPv6")
        enable_cross_zone = optional(bool, false)
      }))
      values            = optional(list(string), [])
    })))

    aws_alb_controller = optional(object({
      eks_cluster_name = optional(string, "")
      region = optional(string, "")
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
    
  })
  default = null
}
