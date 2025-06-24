# HOW TO USE

```
module "eks" {
  source = "./modules/eks"
  metadata = {
    name        = string
    environment = string
    eks_version = string
    region  = string
  }

  cluster_settings = {
    cluster_subnet_ids = list(string)  # Required, min are two, in different AZs
    allowed_cidrs_to_access_cluster_publicly = list(string) # Optional, set default to "0.0.0.0/0"
    set_custom_pod_cidr_block = string  # Optional
    support_type = string # Optional, defaults to "STANDARD"
    ip_family = string # Optional, defaults to "ipv4"
    security_group_ids = list(string) # Optional, EKS will generate one if not specified.
    enable_endpoint_public_access = bool # Optional, defaults to true
    enable_endpoint_private_access = bool  # Optional, defaults to false
    create_eks_admin_access_iam_group = bool  # Optional, defaults to false
    create_eks_custom_access_iam_group = bool  # Optional, defaults to false

    enable_logging = {
      api               = bool # Optional, default to false
      audit             = bool # Optional, default to false
      authenticator     = bool # Optional, default to false
      controllerManager = bool # Optional, default to false
      scheduler         = bool # Optional, default to false
    }

    addons = {
      vpc_cni                         = bool # Optional, default to false
      eks_pod_identity_agent          = bool # Optional, default to true
      snapshot_controller             = bool # Optional, default to false
      aws_guardduty_agent             = bool # Optional, default to false
      amazon_cloudwatch_observability = bool # Optional, default to false
      aws_ebs_csi_driver = {
        fstype = string # Defaults to "ext4"
        ebs_type = string # Defaults to "gp3"
        iopsPerGB =  number # Optional
        encrypted = bool # Defaults to true
      }
      aws_efs_csi_driver = {
        enable          = bool # Defaults to false
        encrypted       = bool # Defaults to true
        subnet_ids      = list(string) # Required if no resource specified.
        efs_resource_id = string # Optional, resource will be created if not specified.
      }
      aws_mountpoint_s3_csi_driver = {
        enable        = bool # Defaults to false
        s3_bucket_arn = string # Optional, resource will be created if not specified.
      }
    }
  }

  node_settings = {
    cluster_name          = string # optional
    node_group_name       = string # optional
    workernode_subnet_ids = list(string)
    taints                = list(map(string)) # Optional, e.g. [{key = "", value = "", effect = ""}, {}]
    labels                = map(string) # Optional, e.g. {"key1" = "value1","key2" = "value2"}
    capacity_config = {
      capacity_type  = string # Optional, default to "ON_DEMAND"
      instance_types = list(string)
      disk_size      = number # Optional, default to 20GB
    }
    scaling_config = {
      desired         = number # Optional, default to 1
      max_size        = number # Optional, default to 1
      min_size        = number # Optional, default to 1
      max_unavailable = number # Optional, default to 1
    }
    remote_access  = { # Optional
      enable       = bool, false # Optional, defaults to false
      ssh_key_name = string
      allowed_security_groups = list(string) # Optional, defaults to "0.0.0.0/0" acccessibility
    }
  }

  fargate_profile = {
    cluster_name  = string # optional
    subnet_ids = list(string)
    fargate_profile_name = string # optional
    namespace = string # optional, if not stated, custom namespace "fargate-space" is specified
  }

  plugins = { # Optional, used as `argument = {}`
    dont_wait_for_helm_install           = bool # Optional, defaults to true
    create_ecr_registry = bool # Optional, defaults to false
    cluster_autoscaler = {
      values = list(string) # Optional, e.g [<<EOF...EOF]
    } 
    metrics_server = {
      values = list(string) # Optional, e.g [<<EOF...EOF]
    }
    aws_alb_controller = {
      vpc_id = string
      values = list(string) # Optional, e.g [<<EOF...EOF]
    }
    nginx_controller = {
      scheme_type       = optional(string, "internet-facing") # OR "internal"
      enable_cross_zone = bool # Optional, default to false
      values            = list(string) # Optional, e.g [<<EOF...EOF]
    }
    argo_cd = {
      values = list(string) # Optional, e.g [<<EOF...EOF]
    }
    external_secrets = {
      values = list(string) # Optional, e.g [<<EOF...EOF]
    }
    secrets_store_csi_driver = {
      values = list(string) # Optional, e.g [<<EOF...EOF]
    }
    loki = {
      values = list(string) # Optional, e.g [<<EOF...EOF]
    }
    prometheus = {
      values = list(string) # Optional, e.g [<<EOF...EOF]
    }
    cert_manager = {
      values = list(string) # Optional, e.g [<<EOF...EOF]
    }
    kubernetes_dashboard = {
      hosts          = list(string)
      use_internally = bool # Optiona, defaults to false
      values = list(string) # Optional, e.g [<<EOF...EOF]
    }
    rancher = {
      host                 = string
      use_internal_ingress = bool # Optiona, defaults to false
      values = list(string) # Optional, e.g [<<EOF...EOF]
    }
    calico_cni = {
      enable = bool # Defaults to false
      cidr   = string  # Should be within the VPC CIDR, and not overlap with subnet CIDRs.
      values = list(string) # Optional, e.g [<<EOF...EOF]
    }
  }
}
```
# OUTPUTS
## EKS
```
# CLUSTER ENDPOINT
endpoint

# KUBECONFIG CERTIFICATE AUTHORITY
kubeconfig-certificate-authority-data

# CLUSTER ID
cluster_id

# CLUSTER NAME
cluster_name

#########################
# BASED ON DATA RESOURCES
#########################
## CLUSTER CERTIFICATE
aws_eks_cluster_certificate_data

## CLUSTER ENDPOINT
aws_eks_cluster_data

## CLUSTER NAME
aws_eks_cluster_name

## CLUSTER TOKEN
aws_eks_cluster_auth

## ECR REGISTRY URL
ecr_registry
```