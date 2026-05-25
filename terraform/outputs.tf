output "bucket_name" {
  value = aws_s3_bucket.storage_bucket.id
}

output "replica_bucket_name" {
  value = aws_s3_bucket.replica_bucket.id
}

output "kms_key_arn" {
  value = aws_kms_key.s3_encrypt.arn
}

output "lambda_arn" {
  value = aws_lambda_function.processor.arn
}