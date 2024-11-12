terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region                   = var.metadata.region
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
}
##########################################################################

provider "helm" {
  kubernetes {
    host                   = module.eks.aws_eks_cluster_data
    token                  = module.eks.aws_eks_cluster_auth
    cluster_ca_certificate = base64decode(module.eks.aws_eks_cluster_certificate_data)
    #config_path = "~/.kube/config"
  }

}

#######################################################################
provider "kubernetes" {
  host                   = module.eks.aws_eks_cluster_data
  token                  = module.eks.aws_eks_cluster_auth
  cluster_ca_certificate = base64decode(module.eks.aws_eks_cluster_certificate_data)
  #config_path = "~/.kube/config"
}