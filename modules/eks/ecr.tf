resource "aws_ecr_repository" "ecr" {
  count                = var.plugins == null ? 0 : var.plugins.create_ecr_registry == null ? 0 : var.plugins.create_ecr_registry ? 1 : 0
  name                 = lower("${var.metadata.name}-${var.metadata.environment}")
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
  force_delete = true
  lifecycle {
    ignore_changes = [image_scanning_configuration]
  }
}

