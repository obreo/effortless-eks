# Time delay after cluster creation
resource "time_sleep" "wait_for_cluster" {
  depends_on = [aws_eks_cluster.cluster]

  # Adjust this create_duration based on your needs
  create_duration = "30s"
}


# EKS NODE GROUP
resource "aws_eks_node_group" "node" {
  count           = var.node_settings != null ? 1 : 0
  cluster_name    = try(var.node_settings.cluster_name, "${var.metadata.name}-default-cluster")
  version         = var.metadata.eks_version
  node_group_name = var.node_settings.node_group_name == null ? var.metadata.name : var.node_settings.node_group_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.node_settings.workernode_subnet_ids

  capacity_type  = try(var.node_settings.capacity_config.capacity_type, "ON_DEMAND")
  disk_size      = try(var.node_settings.capacity_config.disk_size, 20)
  instance_types = var.node_settings.capacity_config.instance_types

  scaling_config {
    desired_size = try(var.node_settings.scaling_config.desired, 1)
    max_size     = try(var.node_settings.scaling_config.max_size, 1)
    min_size     = try(var.node_settings.scaling_config.min_size, 1)
  }

  update_config {
    max_unavailable = try(var.node_settings.scaling_config.max_unavailable, 1)
  }

  dynamic "remote_access" {
    for_each = var.node_settings == null || var.node_settings.remote_access == null ? [] : var.node_settings.remote_access.enable ? [1] : []
    content {
      ec2_ssh_key               = try(var.node_settings.remote_access.ssh_key_name)
      source_security_group_ids = try(var.node_settings.remote_access.allowed_security_groups, null)
    }
  }


  # Handle null var.node_settings for labels
  labels = var.node_settings == null ? {} : var.node_settings.labels != null ? var.node_settings.labels : {}

  # Handle null var.node_settings for taints
  dynamic "taint" {
    for_each = var.node_settings == null ? [] : var.node_settings.taints != null ? var.node_settings.taints : []
    content {
      key    = taint.value["key"]
      value  = taint.value["value"]
      effect = taint.value["effect"]
    }
  }

  depends_on = [
    time_sleep.wait_for_cluster,
    aws_iam_role.node,
    aws_eks_cluster.cluster,
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}