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

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "simple-storage"
}

locals {
  suffix             = formatdate("YYYYMMDDhhmmss", timestamp())
  origin_bucket_name = "${var.project_name}-origin-${local.suffix}"
}

# ------------------------------------------------------------
# Lambda function package
# ------------------------------------------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/lambda.zip"

  excludes = ["__pycache__", "tests", "requirements.txt"]
}

# ------------------------------------------------------------
# S3 Origin Bucket with versioning, encryption, and lifecycle
# ------------------------------------------------------------
resource "aws_s3_bucket" "origin" {
  bucket = local.origin_bucket_name
}

resource "aws_s3_bucket_versioning" "origin" {
  bucket = aws_s3_bucket.origin.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "origin" {
  bucket = aws_s3_bucket.origin.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "origin" {
  bucket = aws_s3_bucket.origin.id

  rule {
    id     = "lifecycle-rules"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "origin" {
  bucket = aws_s3_bucket.origin.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------
# CloudWatch monitoring for Lambda
# ------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.s3_processor.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_metric_filter" "lambda_errors" {
  name           = "${var.project_name}-lambda-errors"
  log_group_name = aws_cloudwatch_log_group.lambda.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "S3ProcessorErrors"
    namespace = "SimpleStorage"
    value     = "1"
  }
}

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "${var.project_name}-lambda-error-alarm"
  alarm_description   = "Alarm when Lambda logs contain ERROR"
  metric_name         = "S3ProcessorErrors"
  namespace           = "SimpleStorage"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
}

# ------------------------------------------------------------
# Lambda function for S3 events
# ------------------------------------------------------------
resource "aws_lambda_function" "s3_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-s3-processor"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "s3_event_processor.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic
  ]
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.origin.arn
}

resource "aws_s3_bucket_notification" "origin" {
  bucket = aws_s3_bucket.origin.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# ------------------------------------------------------------
# IAM Role for Lambda (minimal permissions)
# ------------------------------------------------------------
resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ------------------------------------------------------------
# Outputs
# ------------------------------------------------------------
output "origin_bucket_name" {
  value = aws_s3_bucket.origin.id
}

 

output "lambda_function_name" {
  value = aws_lambda_function.s3_processor.function_name
}