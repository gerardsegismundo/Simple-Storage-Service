resource "aws_sqs_queue" "dlq" {
  name              = "${var.project_name}-dlq"
  kms_master_key_id = "alias/aws/sqs"
}

resource "aws_lambda_event_source_mapping" "dlq" {
  event_source_arn = aws_sqs_queue.dlq.arn
  function_name    = aws_lambda_function.processor.arn
}

resource "aws_cloudwatch_metric_alarm" "dlq_errors" {
  alarm_name          = "${var.project_name}-dlq-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "DLQ has messages - Lambda processing failures detected"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }
}