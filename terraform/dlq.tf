resource "aws_sqs_queue" "dlq" {
  name              = "${var.project_name}-dlq"
  kms_master_key_id = "alias/aws/sqs"
}

resource "aws_lambda_event_source_mapping" "dlq" {
  event_source_arn = aws_sqs_queue.dlq.arn
  function_name    = aws_lambda_function.processor.arn
}