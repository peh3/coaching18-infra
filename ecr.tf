# ECR Repository for Service 1[cite: 4]
resource "aws_ecr_repository" "flask_s3" {
  name                 = var.s3_service_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = var.s3_service_name
  }
}

# ECR Repository for Service 2[cite: 4]
resource "aws_ecr_repository" "flask_sqs" {
  name                 = var.sqs_service_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = var.sqs_service_name
  }
}