# EKS CLUSTER
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster
resource "aws_eks_cluster" "cluster" {
  count    = var.cluster_settings != null ? 1 : 0
  name     = var.metadata.name
  role_arn = aws_iam_role.cluster.arn
  version  = var.metadata.eks_version != "" ? var.metadata.eks_version : null

  enabled_cluster_log_types = var.cluster_settings.enable_logging == null ? [] : compact(flatten([
    var.cluster_settings.enable_logging.api ? ["api"] : [],
    var.cluster_settings.enable_logging.audit ? ["audit"] : [],
    var.cluster_settings.enable_logging.authenticator ? ["authenticator"] : [],
    var.cluster_settings.enable_logging.controllerManager ? ["controllerManager"] : [],
    var.cluster_settings.enable_logging.scheduler ? ["scheduler"] : []
  ]))

  vpc_config {
    subnet_ids              = var.cluster_settings.cluster_subnet_ids
    endpoint_private_access = try(var.cluster_settings.enable_endpoint_private_access, false)
    endpoint_public_access  = try(var.cluster_settings.enable_endpoint_public_access, true)
    public_access_cidrs     = toset(try(var.cluster_settings.allowed_cidrs_to_access_cluster_publicly, ["0.0.0.0/0"]))
    security_group_ids      = try(var.cluster_settings.security_group_ids, [])
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  upgrade_policy {
    support_type = try(var.cluster_settings.support_type, "STANDARD")
  }

  dynamic "kubernetes_network_config" {
    for_each = var.cluster_settings.set_custom_pod_cidr_block != "" ? [1] : [0]
    content {
      service_ipv4_cidr = var.cluster_settings.set_custom_pod_cidr_block # Should be: Private IP block, Doesn't overlap with VPC Subnets but within VPC CIDR, Between /24 and /12 subnet.
      ip_family         = var.cluster_settings.ip_family
    }
  }

  tags = {
    Environment = "${var.metadata.environment}"
    Project     = "${var.metadata.name}"
  }
  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role.cluster
  ]

  #lifecycle {
  #  ignore_changes = [endpoint, certificate_authority]
  #}
}



