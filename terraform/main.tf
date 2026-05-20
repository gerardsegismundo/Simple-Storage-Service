terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "storage_bucket" {
  bucket = var.bucket_name
  acl    = "private"
}

variable "aws_region" {
  description = "AWS region where resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for storage service data."
  type        = string
  default     = "simple-storage-service-bucket"
}

output "bucket_name" {
  description = "The name of the created S3 bucket."
  value       = aws_s3_bucket.storage_bucket.id
}
