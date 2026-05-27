# resource "aws_kms_key" "s3" {
#   description = "S3 encryption key for ${var.project_name}"
# }

# resource "aws_kms_alias" "s3" {
#   name          = "alias/${var.project_name}-s3"
#   target_key_id = aws_kms_key.s3.key_id
# }