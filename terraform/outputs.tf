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

output "website_url" {
  value = "${aws_s3_bucket.primary.bucket}.s3-website-${var.primary_region}.amazonaws.com"
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.website.id
}

output "website_url" {
  value = aws_cloudfront_distribution.website.domain_name
}