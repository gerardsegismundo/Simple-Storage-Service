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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# ------------------------------------------------------------
# Naming
# ------------------------------------------------------------
locals {
  timestamp    = formatdate("YYYYMMDDhhmmss", timestamp())
  bucket_name  = "segismundo-s3-origin-${local.timestamp}"
  replica_name = "segismundo-s3-replica-${local.timestamp}"
  lambda_name  = "s3-event-processor"
}

# ------------------------------------------------------------
# KMS Key
# ------------------------------------------------------------
resource "aws_kms_key" "s3_encrypt" {
  description         = "S3 encryption key"
  enable_key_rotation = true
}

resource "aws_kms_alias" "s3_alias" {
  name          = "alias/s3-key-${local.timestamp}"
  target_key_id = aws_kms_key.s3_encrypt.key_id
}

# ------------------------------------------------------------
# Buckets
# ------------------------------------------------------------
resource "aws_s3_bucket" "storage_bucket" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket" "replica_bucket" {
  bucket = local.replica_name
}

# ------------------------------------------------------------
# Versioning (SAFE)
# ------------------------------------------------------------
resource "aws_s3_bucket_versioning" "storage_versioning" {
  bucket = aws_s3_bucket.storage_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "replica_versioning" {
  bucket = aws_s3_bucket.replica_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------------------------------------------
# Encryption
# ------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "storage_encryption" {
  bucket = aws_s3_bucket.storage_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_encrypt.arn
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replica_encryption" {
  bucket = aws_s3_bucket.replica_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "storage_lifecycle" {
  bucket = aws_s3_bucket.storage_bucket.id

  rule {
    id     = "main-lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# ------------------------------------------------------------
# Static Website Hosting
# ------------------------------------------------------------
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.storage_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# ------------------------------------------------------------
# Website Files (public access for static hosting)
# Note: These objects need public read access, so we use AES256
# for website files while keeping KMS for other objects
# ------------------------------------------------------------
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.storage_bucket.id
  key          = "index.html"
  source       = "${path.module}/../index.html"
  content_type = "text/html"

  etag = filemd5("${path.module}/../index.html")
}

resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.storage_bucket.id
  key          = "error.html"
  source       = "${path.module}/../error.html"
  content_type = "text/html"

  etag = filemd5("${path.module}/../error.html")
}

# ------------------------------------------------------------
# IAM Role for Replication
# ------------------------------------------------------------
resource "aws_iam_role" "replication_role" {
  name = "s3-replication-role-clean"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "s3.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "replication_policy" {
  role = aws_iam_role.replication_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionForReplication",
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ],
        Resource = "${aws_s3_bucket.storage_bucket.arn}/*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ],
        Resource = "${aws_s3_bucket.replica_bucket.arn}/*"
      }
    ]
  })
}

# ------------------------------------------------------------
# Replication
# ------------------------------------------------------------
resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [
    aws_s3_bucket_versioning.storage_versioning,
    aws_s3_bucket_versioning.replica_versioning
  ]

  role   = aws_iam_role.replication_role.arn
  bucket = aws_s3_bucket.storage_bucket.id

  rule {
    id     = "replication-rule"
    status = "Enabled"

    destination {
      bucket = aws_s3_bucket.replica_bucket.arn
    }
  }
}

# ------------------------------------------------------------
# Lambda (kept simple)
# ------------------------------------------------------------
resource "aws_iam_role" "lambda_role" {
  name = "lambda-s3-role-clean"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../lambda/s3_event_processor.py"
  output_path = "../lambda/s3_event_processor.zip"
}

resource "aws_lambda_function" "processor" {
  function_name    = local.lambda_name
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.11"
  handler          = "s3_event_processor.lambda_handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      BUCKET = aws_s3_bucket.storage_bucket.id
    }
  }
}