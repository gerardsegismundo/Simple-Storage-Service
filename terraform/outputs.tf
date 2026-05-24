output "bucket_name" {
  description = "The name of the created S3 bucket."
  value       = aws_s3_bucket.storage_bucket.id
}

output "replica_bucket_name" {
  description = "The name of the cross-region replication bucket."
  value       = aws_s3_bucket.replica_bucket.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for S3 encryption."
  value       = aws_kms_key.s3_encrypt.arn
}

output "lambda_role_arn" {
  description = "IAM role ARN used by the Lambda processor."
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function."
  value       = aws_lambda_function.s3_event_processor.arn
}
