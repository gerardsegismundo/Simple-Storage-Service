variable "aws_region" {
  description = "AWS region where the primary bucket and resources are created."
  type        = string
  default     = "us-east-1"
}

variable "replica_region" {
  description = "AWS region for cross-region replication destination."
  type        = string
  default     = "us-west-2"
}

variable "bucket_name" {
  description = "Primary S3 bucket name for the static website and content."
  type        = string
  default     = "simple-storage-service-bucket"
}

variable "replica_bucket_name" {
  description = "Cross-region replication bucket name."
  type        = string
  default     = "simple-storage-service-replica-bucket"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function for S3 upload events."
  type        = string
  default     = "simple-storage-service-processor"
}

variable "dynamodb_lock_table" {
  description = "DynamoDB table name used for Terraform state locking."
  type        = string
  default     = "simple-storage-service-lock-table"
}

variable "kms_key_alias" {
  description = "KMS alias used for S3 bucket encryption."
  type        = string
  default     = "alias/simple-storage-service-kms"
}
