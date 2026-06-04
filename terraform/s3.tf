
locals {
  suffix = formatdate("YYYYMMDDhhmmss", timestamp())
}

# =========================
# PRIMARY BUCKET 
# =========================
resource "aws_s3_bucket" "primary" {
  bucket        = "${var.project_name}-primary-${local.suffix}"
  force_destroy = true
}

# =========================
# VERSIONING
# =========================
resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# =========================
# AES256 ENCRYPTION 
# =========================
resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# =========================
# LIFECYCLE -- TRANSITION TO STANDARD_IA AND NONCURRENT VERSION EXPIRATION
# =========================
resource "aws_s3_bucket_lifecycle_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "lifecycle"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7 
    }

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

# =========================
# PUBLIC ACCESS BLOCK
# =========================
resource "aws_s3_bucket_public_access_block" "primary" {
  bucket = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}