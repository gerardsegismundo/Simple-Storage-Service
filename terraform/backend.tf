terraform {
  backend "s3" {
    bucket   = "s3-platform-tf-state-main"
    key      = "simple-storage-service/terraform.tfstate"
    region   = "us-east-1"
    encrypt  = true
  }
}