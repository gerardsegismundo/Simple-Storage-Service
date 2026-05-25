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

# ------------------------------------------------------------
# Variables
# ------------------------------------------------------------
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = ""
}

# ------------------------------------------------------------
# Locals
# ------------------------------------------------------------
locals {
  bucket_name = var.bucket_name != "" ? var.bucket_name : "simple-storage-${formatdate("YYYYMMDDhhmmss", timestamp())}"
}

# ------------------------------------------------------------
# Simple S3 Bucket (no ACLs, no KMS, versioning + AES256)
# ------------------------------------------------------------
resource "aws_s3_bucket" "storage" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ------------------------------------------------------------
# Static Website Hosting (optional - enable by setting var.enable_website = true)
# ------------------------------------------------------------
variable "enable_website" {
  description = "Enable static website hosting"
  type        = bool
  default     = false
}

resource "aws_s3_bucket_website_configuration" "storage" {
  count  = var.enable_website ? 1 : 0
  bucket = aws_s3_bucket.storage.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# ------------------------------------------------------------
# Website Files (only if website hosting is enabled)
# ------------------------------------------------------------
resource "aws_s3_object" "index_html" {
  count        = var.enable_website ? 1 : 0
  bucket       = aws_s3_bucket.storage.id
  key          = "index.html"
  source       = "${path.module}/../index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "error_html" {
  count        = var.enable_website ? 1 : 0
  bucket       = aws_s3_bucket.storage.id
  key          = "error.html"
  source       = "${path.module}/../error.html"
  content_type = "text/html"
}

# ------------------------------------------------------------
# Outputs
# ------------------------------------------------------------
output "bucket_name" {
  value = aws_s3_bucket.storage.id
}

output "website_endpoint" {
  value = var.enable_website ? "${aws_s3_bucket.storage.id}.s3-website-${var.aws_region}.amazonaws.com" : null
}