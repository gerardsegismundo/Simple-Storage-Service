variable "aws_region" {
  description = "AWS region where resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for storage service data."
  type        = string
  default     = "simple-storage-service-bucket"
}
