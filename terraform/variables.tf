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

variable "kms_key_alias" {
  description = "KMS alias used for S3 bucket encryption."
  type        = string
  default     = "alias/simple-storage-service-kms"
}

variable "mfa_serial_number" {
  description = "IAM MFA device serial ARN for MFA Delete (required when enabling MFA Delete). Pass via TF_VAR_mfa_serial_number or a var file. Leave empty to skip."
  type        = string
  default     = ""
  sensitive   = true
}

variable "mfa_token_code" {
  description = "Current 6-digit MFA token code (required when enabling MFA Delete). Pass via TF_VAR_mfa_token_code or a var file. Leave empty to skip."
  type        = string
  default     = ""
  sensitive   = true
}

variable "s3_access_point_access_principal" {
  description = "IAM principal ARN that may use the S3 Access Points. Default '*' is open — set to a specific ARN in production."
  type        = string
  default     = "*"
}

variable "audit_logs_bucket_name" {
  description = "Name for the CloudTrail audit log bucket. Leave empty to auto-generate a unique name."
  type        = string
  default     = ""
}
