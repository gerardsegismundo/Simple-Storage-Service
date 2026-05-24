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
        Sid      = "Allow use of the key for S3 encryption"
        Effect   = "Allow"
        Principal = {
          AWS = "*"
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

resource "aws_s3_bucket" "replica_bucket" {
  provider = aws.secondary
  bucket   = var.replica_bucket_name
  acl      = "private"
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

resource "aws_s3_bucket_public_access_block" "storage_bucket_public_access" {
  bucket = aws_s3_bucket.storage_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.storage_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PublicReadForWebsite"
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = [
          "${aws_s3_bucket.storage_bucket.arn}/*"
        ]
      }
    ]
  })
}

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
        Effect   = "Allow"
        Action   = [
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
        Effect   = "Allow"
        Action   = [
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
        Effect   = "Allow"
        Action   = [
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

resource "aws_dynamodb_table" "terraform_lock" {
  name         = var.dynamodb_lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
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
        Sid = "LambdaS3Access",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.storage_bucket.arn,
          "${aws_s3_bucket.storage_bucket.arn}/*"
        ]
      },
      {
        Sid = "LambdaLogging",
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

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
