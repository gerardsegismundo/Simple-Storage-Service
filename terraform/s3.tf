locals {
  suffix = formatdate("YYYYMMDDhhmmss", timestamp())
}

# =========================
# PRIMARY BUCKET
# =========================
resource "aws_s3_bucket" "primary" {
  bucket        = "${var.project_name}-primary-${local.suffix}"
  force_destroy = true

  object_lock_enabled = true
}

# Static website hosting
resource "aws_s3_bucket_website_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# KMS Encryption + Bucket Keys
resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }

    bucket_key_enabled = true
  }
}

# Lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "lifecycle"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

# Public access block (secure)
resource "aws_s3_bucket_public_access_block" "primary" {
  bucket = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =========================
# ACCESS POINT (REQUIRED)
# =========================
resource "aws_s3_access_point" "primary" {
  bucket = aws_s3_bucket.primary.id
  name   = "${var.project_name}-ap"
}