# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   source_dir  = "${path.module}/../lambda"
#   output_path = "${path.module}/lambda.zip"
# }

# resource "aws_iam_role" "lambda" {
#   name = "${var.project_name}-lambda-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect    = "Allow"
#       Principal = { Service = "lambda.amazonaws.com" }
#       Action    = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "lambda_basic" {
#   role       = aws_iam_role.lambda.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# resource "aws_lambda_function" "processor" {
#   filename         = data.archive_file.lambda_zip.output_path
#   function_name    = "${var.project_name}-processor"
#   role             = aws_iam_role.lambda.arn
#   handler          = "s3_event_processor.lambda_handler"
#   runtime          = "python3.11"
#   source_code_hash = data.archive_file.lambda_zip.output_base64sha256
# }

# resource "aws_lambda_permission" "allow_s3" {
#   statement_id  = "AllowS3Invoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.processor.function_name
#   principal     = "s3.amazonaws.com"
#   source_arn    = aws_s3_bucket.primary.arn
# }

# resource "aws_s3_bucket_notification" "event" {
#   bucket = aws_s3_bucket.primary.id

#   lambda_function {
#     lambda_function_arn = aws_lambda_function.processor.arn
#     events              = ["s3:ObjectCreated:*"]
#   }

#   depends_on = [aws_lambda_permission.allow_s3]
# }