output "ecs_cluster_name" {
  description = "Cluster name to supply to App CI/CD variables"
  value       = aws_ecs_cluster.main.name
}

output "ecr_s3_repository_url" {
  description = "ECR URL for Flask S3 App"
  value       = aws_ecr_repository.flask_s3.repository_url
}

output "ecr_sqs_repository_url" {
  description = "ECR URL for Flask SQS App"
  value       = aws_ecr_repository.flask_sqs.repository_url
}

output "s3_bucket_name" {
  description = "S3 target bucket name"
  value       = aws_s3_bucket.app_bucket.id
}

output "sqs_queue_url" {
  description = "SQS queue URL"
  value       = aws_sqs_queue.app_queue.url
}