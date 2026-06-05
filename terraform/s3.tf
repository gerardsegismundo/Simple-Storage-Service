
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

resource "aws_s3_bucket_website_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# =========================
# PUBLIC READ BLOCK
# =========================
resource "aws_s3_bucket_policy" "primary_website" {
  bucket = aws_s3_bucket.primary.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.primary.arn}/*"
    }]
  })
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


resource "aws_s3_bucket_public_access_block" "primary" {
  bucket = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}