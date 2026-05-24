terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "secondary"
  region = var.replica_region
}

data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# KMS Key for S3 encryption (bucket keys enabled in storage_bucket)
# ---------------------------------------------------------------------------
resource "aws_kms_key" "s3_encrypt" {
  description             = "KMS key for S3 encryption and bucket key use."
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Allow administration of the key"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key for S3 encryption"
        Effect = "Allow"
        Principal = {
          AWS = var.s3_access_point_access_principal
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:ReEncrypt*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "s3_alias" {
  name          = var.kms_key_alias
  target_key_id = aws_kms_key.s3_encrypt.key_id
}

# ---------------------------------------------------------------------------
# Replica bucket (destination for cross-region replication)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "replica_bucket" {
  provider      = aws.secondary
  bucket        = var.replica_bucket_name
  acl           = "private"
  force_destroy = false

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    enabled = true
    id      = "replica-archive"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}

# ---------------------------------------------------------------------------
# Primary storage bucket (origin / static website host)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "storage_bucket" {
  bucket = var.bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.s3_encrypt.arn
      }
      bucket_key_enabled = true
    }
  }

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  lifecycle_rule {
    id      = "archive-lifecycle"
    enabled = true

    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      days = 90
    }
  }

  object_lock_configuration {
    object_lock_enabled = "Enabled"
    rule {
      default_retention {
        mode  = "GOVERNANCE"
        days  = 30
      }
    }
  }

  replication_configuration {
    role = aws_iam_role.replication_role.arn

    rules {
      id     = "s3-replication-rule"
      status = "Enabled"

      destination {
        bucket        = aws_s3_bucket.replica_bucket.arn
        storage_class = "STANDARD"
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Supporting bucket configurations (logging, cors, access points, ownership)
# These are top-level resources, NOT nested inside aws_s3_bucket.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_logging" "storage_bucket_access_logs" {
  bucket        = aws_s3_bucket.storage_bucket.id
  target_bucket = aws_s3_bucket.audit_logs.id
  target_prefix = "s3-origin-logs/"
}

resource "aws_s3_bucket_cors_configuration" "storage_bucket_cors" {
  bucket = aws_s3_bucket.storage_bucket.id

  cors_rule {
    allowed_methods = ["GET", "PUT", "POST", "HEAD", "DELETE"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_access_point" "upload_access_point" {
  bucket = aws_s3_bucket.storage_bucket.id
  name   = "simple-storage-service-uploads"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowUploads"
        Effect = "Allow"
        Principal = {
          AWS = var.s3_access_point_access_principal
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.storage_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:prefix" = ["uploads/"]
          }
        }
      }
    ]
  })
}

resource "aws_s3_access_point" "readonly_access_point" {
  bucket = aws_s3_bucket.storage_bucket.id
  name   = "simple-storage-service-readonly"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadOnly"
        Effect = "Allow"
        Principal = {
          AWS = var.s3_access_point_access_principal
        }
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.storage_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_ownership_controls" "replica_ownership" {
  bucket = aws_s3_bucket.replica_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# ---------------------------------------------------------------------------
# Public access block + bucket policy
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "storage_bucket_public_access" {
  bucket = aws_s3_bucket.storage_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.storage_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAclACL"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "s3:GetBucketAcl",
          "s3:PutBucketAcl"
        ]
        Resource = [
          "${aws_s3_bucket.storage_bucket.arn}",
          "${aws_s3_bucket.storage_bucket.arn}/*"
        ]
      },
      {
        Sid       = "DenyNonEncryptedOutbound"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.storage_bucket.arn}/*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# IAM roles and policies
# ---------------------------------------------------------------------------
resource "aws_iam_role" "replication_role" {
  name = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "replication_policy" {
  name = "s3-replication-policy"
  role = aws_iam_role.replication_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectLegalHold",
          "s3:GetObjectRetention"
        ]
        Resource = [
          "${aws_s3_bucket.storage_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectVersionAcl",
          "s3:PutObjectTagging"
        ]
        Resource = [
          "${aws_s3_bucket.replica_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [
          aws_kms_key.s3_encrypt.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "s3-event-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "s3-event-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaS3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.storage_bucket.arn,
          "${aws_s3_bucket.storage_bucket.arn}/*"
        ]
      },
      {
        Sid    = "LambdaLogging"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# ---------------------------------------------------------------------------
# Lambda function package + deployment
# ---------------------------------------------------------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../lambda/s3_event_processor.py"
  output_path = "../lambda/s3_event_processor.zip"
}

resource "aws_lambda_function" "s3_event_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "s3_event_processor.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  publish          = true

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.storage_bucket.id
    }
  }
}

resource "aws_lambda_permission" "allow_bucket_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_event_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.storage_bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.storage_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_event_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
    filter_suffix       = ".jpg"
  }

  depends_on = [aws_lambda_permission.allow_bucket_invoke]
}

# ---------------------------------------------------------------------------
# MFA Delete automation (null_resource + scripts/mfa-setup.sh)
# ---------------------------------------------------------------------------
resource "null_resource" "mfa_delete_setup" {
  triggers = {
    bucket_name             = aws_s3_bucket.storage_bucket.id
    mfa_delete_note_version = "1"
  }

  provisioner "local-exec" {
    command = <<EOT
if [ -z "${var.mfa_serial_number}" ] || [ -z "${var.mfa_token_code}" ]; then
  echo "SKIPPING: MFA Delete requires an MFA session token."
  echo "Set TF_VAR_mfa_serial_number and TF_VAR_mfa_token_code to enable."
  exit 0
fi
aws s3api put-bucket-versioning \
  --bucket "${aws_s3_bucket.storage_bucket.id}" \
  --versioning-configuration Status=Enabled,MFADelete=Enabled \
  --mfa "${var.mfa_serial_number} ${var.mfa_token_code}"
EOT
  }
}