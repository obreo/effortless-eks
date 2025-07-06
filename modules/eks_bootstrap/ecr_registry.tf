resource "aws_ecr_repository" "ecr" {
  count                = var.integrations == null ? 0 : var.integrations.ecr_registry != null ? 1 : 0
  name                 = lower("${var.integrations.ecr_registry.name}")
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
  force_delete = true
  lifecycle {
    ignore_changes = [image_scanning_configuration]
  }
}

