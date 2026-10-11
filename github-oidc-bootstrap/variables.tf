variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for all resources"
}
variable "prefix" {
  type        = string
  default     = "tk-coaching18"
  description = "Prefix for all resources"
}

variable "name" {
  type        = string
  default     = "coaching18"
  description = "Name for all resources"
}

# ==========================================================
# Variables & Outputs
# ==========================================================
variable "github_repository_username" {
  description = "GitHub repository username"
  type        = string
  default     = "peh3" #[cite: 9]
}

variable "github_app_repository_name" {
  description = "GitHub repository name for application"
  type        = string
  default     = "coaching18-app" #[cite: 9]
}

variable "github_infra_repository_name" {
  description = "GitHub repository name for Terraform infra"
  type        = string
  default     = "coaching18-infra"
}

variable "tfstate_bucket_name" {
  description = "S3 bucket storing terraform state"
  type        = string
  default     = "sctp-tfstate-ce13" #[cite: 7]
}
