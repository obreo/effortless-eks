module "vpc" {
  source = "./modules/vpc"
  name   = var.metadata.name
  vpc_settings = {
    vpc_cidr_block             = "192.168.0.0/19"
    public_subnet_cidr_blocks  = ["192.168.0.0/21", "192.168.8.0/21"]
    private_subnet_cidr_blocks = ["192.168.16.0/21"]
    create_private_subnets_nat = true
    availability_zones         = ["${var.metadata.region}a", "${var.metadata.region}b"]
    security_group = {
      ip_protocol = "-1"
      ssh_port = {
        cidr_ipv4 = "0.0.0.0/0"
      }
    }
    include_eks_tags = {
      cluster_name = var.metadata.name
    }
  }
}

module "eks" {
  source = "./modules/eks"
  metadata = {
    name        = var.metadata.name
    environment = var.metadata.environment
    eks_version = "1.30"
    region      = var.metadata.region
  }

  cluster_settings = {
    cluster_subnet_ids                = module.vpc.public_subnet_cidr_blocks
    security_group_ids                = [module.vpc.cluster_security_group_id]
    enable_endpoint_public_access     = true
    enable_endpoint_private_access    = true
    create_eks_admin_access_iam_group = true
    ip_family                         = "ipv4"

    addons = {
      vpc_cni                         = true
      eks_pod_identity_agent          = true
      amazon_cloudwatch_observability = true
      aws_ebs_csi_driver              = {}
      aws_efs_csi_driver = {
        enable     = true
        subnet_ids = module.vpc.private_subnet_cidr_blocks
      }
      aws_mountpoint_s3_csi_driver = {
        enable = true
      }

    }
  }

  node_settings = {
    cluster_name          = module.eks.cluster_name
    workernode_subnet_ids = module.vpc.private_subnet_cidr_blocks
    remote_access = {
      enable       = true
      ssh_key_name = ""
    }
    labels = {
      "environment" = "${var.metadata.environment}",
    }
    capacity_config = {
      instance_types = ["t3a.xlarge"]
      disk_size      = 20 # Optional, default to 20GB
    }
    scaling_config = {
      desired         = 1 # Optional, default to 1
      max_size        = 2 # Optional, default to 1
      min_size        = 1 # Optional, default to 1
      max_unavailable = 1 # Optional, default to 1
    }
  }

  plugins = {
    create_ecr_registry = true
    cluster_autoscaler  = {}
    metrics_server      = {}
    cert_manager        = {}
    argo_cd             = {}
    nginx_controller    = {}
    aws_alb_controller = {
      vpc_id = module.vpc.vpc_id
    }
    rancher = {
      host                 = ""
    }
  }
  depends_on = [module.vpc]
}