output "primary_bucket" {
  value = aws_s3_bucket.primary.id
}

output "replica_bucket" {
  value = aws_s3_bucket.replica.id
}

# output "access_point" {
#   value = aws_s3_access_point.primary.arn
# }

output "lambda_function" {
  value = aws_lambda_function.processor.function_name
}