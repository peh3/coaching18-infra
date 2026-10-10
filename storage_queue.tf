resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket for Service 1 file uploads[cite: 4]
resource "aws_s3_bucket" "app_bucket" {
  bucket        = "${var.prefix}-flask-upload-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "${var.prefix}-flask-upload-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "app_bucket_pab" {
  bucket = aws_s3_bucket.app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SQS Queue for Service 2 message input[cite: 4]
resource "aws_sqs_queue" "app_queue" {
  name                      = "${var.prefix}-flask-message-queue"
  message_retention_seconds = 86400

  tags = {
    Name = "${var.prefix}-flask-message-queue"
  }
}