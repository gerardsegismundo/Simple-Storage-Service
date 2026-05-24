output "bucket_name" {
  description = "The name of the created S3 bucket (origin / primary)."
  value       = aws_s3_bucket.storage_bucket.id
}

output "replica_bucket_name" {
  description = "The name of the cross-region replication bucket (DR)."
  value       = aws_s3_bucket.replica_bucket.id
}

output "region" {
  description = "Primary AWS region."
  value       = var.aws_region
}

output "replica_region" {
  description = "Cross-region replication destination region."
  value       = var.replica_region
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for S3 encryption."
  value       = aws_kms_key.s3_encrypt.arn
}

output "kms_key_alias" {
  description = "Alias of the KMS key used for S3 encryption."
  value       = aws_kms_alias.s3_alias.name
}

output "audit_logs_bucket_name" {
  description = "Name of the CloudTrail / S3 access log bucket."
  value       = aws_s3_bucket.audit_logs.id
}

output "audit_logs_bucket_arn" {
  description = "ARN of the CloudTrail / S3 access log bucket."
  value       = aws_s3_bucket.audit_logs.arn
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail audit trail."
  value       = aws_cloudtrail.s3_audit_trail.name
}

output "upload_access_point_arn" {
  description = "ARN of the upload-focused S3 Access Point."
  value       = aws_s3_access_point.upload_access_point.arn
}

output "readonly_access_point_arn" {
  description = "ARN of the read-only S3 Access Point."
  value       = aws_s3_access_point.readonly_access_point.arn
}

output "lambda_role_arn" {
  description = "IAM role ARN used by the S3 event Lambda processor."
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_function_arn" {
  description = "ARN of the deployed S3 event Lambda processor."
  value       = aws_lambda_function.s3_event_processor.arn
}

output "lambda_function_name" {
  description = "Name of the deployed S3 event Lambda processor."
  value       = aws_lambda_function.s3_event_processor.function_name
}

output "encryption_details" {
  description = "Encryption configuration summary."
  value = {
    bucket_encryption = "aws:kms with customer-managed key"
    kms_key_arn       = aws_kms_key.s3_encrypt.arn
    kms_key_alias     = aws_kms_alias.s3_alias.name
    bucket_keys       = true
  }
}

output "replication_details" {
  description = "Cross-region replication configuration summary."
  value = {
    status          = one(aws_s3_bucket.storage_bucket.replication_configuration[0].rules[*].status)
    destination_arn = one(aws_s3_bucket.storage_bucket.replication_configuration[0].rules[*].destination[0].bucket)
    role_arn        = aws_iam_role.replication_role.arn
  }
}

output "security_details" {
  description = "Security configuration summary."
  value = {
    versioning_enabled         = true
    mfa_delete                 = "Enabled manually via scripts/mfa-setup.sh"
    object_lock_enabled        = true
    object_lock_mode           = aws_s3_bucket.storage_bucket.object_lock_configuration[0].rule[0].default_retention[0].mode
    object_lock_retention_days = aws_s3_bucket.storage_bucket.object_lock_configuration[0].rule[0].default_retention[0].days
    block_public_acls          = aws_s3_bucket_public_access_block.storage_bucket_public_access.block_public_acls
    block_public_policy        = aws_s3_bucket_public_access_block.storage_bucket_public_access.block_public_policy
    restrict_public_buckets    = aws_s3_bucket_public_access_block.storage_bucket_public_access.restrict_public_buckets
    encryption_in_transit      = "Enforced (deny non-TLS)"
  }
}