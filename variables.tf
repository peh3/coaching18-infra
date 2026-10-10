variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Target AWS region"
}

variable "prefix" {
  type        = string
  default     = "tk-coaching18"
  description = "Prefix for all resources"
}

variable "vpc_id" {
  type        = string
  default     = "vpc-071dc429d54e64259"
  description = "Target VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  default     = ["subnet-07fe08d5909e677db", "subnet-00b4c98869b996d86"]
  description = "Target Subnet IDs for ECS tasks"
}

variable "s3_service_name" {
  type        = string
  default     = "tk-coaching18-flask-s3-service"
  description = "Name for S3 upload service and ECR repo"
}

variable "sqs_service_name" {
  type        = string
  default     = "tk-coaching18-flask-sqs-service"
  description = "Name for SQS messaging service and ECR repo"
}