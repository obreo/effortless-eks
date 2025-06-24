# This is used to create role assigned to an empty groups with different credentials. e.g. Admins, dev..etc

# Admin group:
# 1. Role Policy
resource "aws_iam_role_policy" "admin_group" {
  count = var.cluster_settings == null ? 0 : var.cluster_settings.create_eks_admin_access_iam_group == false ? 0 : 1
  name  = "${var.metadata.environment}-${var.metadata.name}-admin-group"
  role  = aws_iam_role.admin_group[count.index].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:*"
        ]
        Effect   = "Allow"
        Resource = "${aws_eks_cluster.cluster[count.index].arn}"
      }
    ]
  })
}

# 2. Role
## Get current IAM user
data "aws_caller_identity" "current" {}
## Write the role
resource "aws_iam_role" "admin_group" {
  count = var.cluster_settings == null ? 0 : var.cluster_settings.create_eks_admin_access_iam_group == false ? 0 : 1
  name  = "${var.metadata.environment}-${var.metadata.name}-eks-admin-auth"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = {
    project-related = "${var.metadata.name}-eks-cluster"
    environment     = "${var.metadata.environment}"
    access          = "admin-access"
    caution         = "requires-rbac-applied-to-eks-access-group"
  }
}

# 3. EKS Role Access Association
resource "aws_eks_access_entry" "admin_group" {
  count             = var.cluster_settings == null ? 0 : var.cluster_settings.create_eks_admin_access_iam_group == false ? 0 : 1
  cluster_name      = aws_eks_cluster.cluster[count.index].name
  principal_arn     = aws_iam_role.admin_group[count.index].arn
  kubernetes_groups = ["admin-group"]
}
######
# 1. IAM Users Group
resource "aws_iam_group" "admin_group" {
  count = var.cluster_settings == null ? 0 : var.cluster_settings.create_eks_admin_access_iam_group == false ? 0 : 1
  name  = "${var.metadata.name}-admin-group"
}
# 2. Create policy for the group to assume the role:
resource "aws_iam_group_policy" "admin_group" {
  count = var.cluster_settings == null ? 0 : var.cluster_settings.create_eks_admin_access_iam_group == false ? 0 : 1
  name  = "${var.metadata.name}-admin-group"
  group = aws_iam_group.admin_group[count.index].name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole"
        Effect   = "Allow"
        Resource = "${aws_iam_role.admin_group[count.index].arn}"
      }
    ]
  })
}

#################################################################################################################
# Custom EKS Access Association: Minimal IAM access
#################################################################################################################
# Custom group:
# 1. Role Policy
resource "aws_iam_role_policy" "custom_group" {
  count = var.cluster_settings == null ? 0 : length(var.cluster_settings.create_eks_custom_access_iam_group) == 0 ? 0 : 1
  name  = "${var.metadata.environment}-${var.metadata.name}-custom-group"
  role  = aws_iam_role.custom_group[count.index].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = var.cluster_settings.create_eks_custom_access_iam_group
        Effect   = "Allow"
        Resource = "${aws_eks_cluster.cluster[count.index].arn}"
      }
    ]
  })
}

# 2. Role
## Write the role
resource "aws_iam_role" "custom_group" {
  count = var.cluster_settings == null ? 0 : length(var.cluster_settings.create_eks_custom_access_iam_group) == 0 ? 0 : 1
  name  = "${var.metadata.environment}-${var.metadata.name}-custom-group"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = {
    project-related = "${var.metadata.name}-eks-cluster"
    environment     = "${var.metadata.environment}"
    access          = "custom-access"
    caution         = "requires-rbac-applied-to-eks-access-group"
  }
}


# 3. EKS Role Access Association
resource "aws_eks_access_entry" "custom_group" {
  count = var.cluster_settings == null ? 0 : length(var.cluster_settings.create_eks_custom_access_iam_group) == 0 ? 0 : 1
  cluster_name      = aws_eks_cluster.cluster[count.index].name
  principal_arn     = aws_iam_role.custom_group[count.index].arn
  kubernetes_groups = ["limited-access-group"]
}
######
# 1. IAM Users Group
resource "aws_iam_group" "custom_group" {
  count = var.cluster_settings == null ? 0 : length(var.cluster_settings.create_eks_custom_access_iam_group) == 0 ? 0 : 1
  name  = "${var.metadata.name}-custom-group"
}
# 2. Assume role policy:
resource "aws_iam_group_policy" "custom_group" {
  count = var.cluster_settings == null ? 0 : length(var.cluster_settings.create_eks_custom_access_iam_group) == 0 ? 0 : 1
  name  = "${var.metadata.environment}-${var.metadata.name}-assume-policy"
  group = aws_iam_group.custom_group[count.index].name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole"
        Effect   = "Allow"
        Resource = "${aws_iam_role.custom_group[count.index].arn}"
      }
    ]
  })
}