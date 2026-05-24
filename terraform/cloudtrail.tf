# ---------------------------------------------------------------------------
# CloudTrail + Audit-Log S3 Bucket
# Depends on: aws_kms_key.s3_encrypt (referenced in event selectors)
# Do NOT declare a `terraform { required_providers { ... } }` block here —
# provider configuration is defined once in main.tf.
# ---------------------------------------------------------------------------

locals {
  audit_bucket_name = var.audit_logs_bucket_name != "" ? var.audit_logs_bucket_name : "s3-audit-logs-${random_id.trail_suffix.hex}"
}

resource "random_id" "trail_suffix" {
  byte_length = 6
}

# Bucket that receives CloudTrail and server-access logs
resource "aws_s3_bucket" "audit_logs" {
  bucket = local.audit_bucket_name

  force_destroy = false

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    id      = "audit-log-365-day-retention"
    enabled = true
    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "audit_logs_block" {
  bucket                  = aws_s3_bucket.audit_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "audit_bucket_policy" {
  bucket = aws_s3_bucket.audit_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudTrailPut"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.audit_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AllowCloudTrailGetBucketAcl"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.audit_logs.arn
      },
      # Allow S3 server-access logging to write to this bucket
      {
        Sid    = "AllowS3ServerAccessLogging"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.audit_logs.arn}/*"
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# CloudTrail Trail
# ---------------------------------------------------------------------------
resource "aws_cloudtrail" "s3_audit_trail" {
  name                          = "s3-service-audit-trail"
  s3_bucket_name                = aws_s3_bucket.audit_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  depends_on = [aws_s3_bucket_policy.audit_bucket_policy]

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.storage_bucket.arn}/*"]
    }

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.replica_bucket.arn}/*"]
    }
  }

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Bucket"
      values = [aws_s3_bucket.storage_bucket.arn, aws_s3_bucket.replica_bucket.arn]
    }
  }

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::KMS::Key"
      values = [aws_kms_key.s3_encrypt.arn]
    }
  }
}
