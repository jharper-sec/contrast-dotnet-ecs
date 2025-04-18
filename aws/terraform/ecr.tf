# ecr.tf - Creates the ECR repository for storing the Docker images

resource "aws_ecr_repository" "contrast_demo" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "demo_policy" {
  repository = aws_ecr_repository.contrast_demo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep only the last 5 images",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 5
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}
