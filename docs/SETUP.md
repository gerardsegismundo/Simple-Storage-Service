# Simple Storage Service (S3) — Setup Guide

This guide walks through deploying the minimal S3 + Lambda + CloudTrail architecture.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Install AWS CLI and Terraform](#install-aws-cli-and-terraform)
3. [Configure AWS Credentials](#configure-aws-credentials)
4. [Deploy with Terraform](#deploy-with-terraform)
5. [Test Lambda Integration](#test-lambda-integration)

---

## Prerequisites

| Tool | Version |
|---|---|
| Python | 3.9+ |
| Terraform | >= 1.0 |
| AWS CLI | 2.x |

---

## Install AWS CLI and Terraform

### AWS CLI

```bash
# macOS (Homebrew)
brew install awscli

# Ubuntu / Debian
sudo apt-get update && sudo apt-get install -y awscli
```

### Terraform

```bash
# macOS
brew install terraform

# Ubuntu
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform
```

---

## Configure AWS Credentials

```bash
aws configure
```

Or set environment variables:

```bash
export AWS_ACCESS_KEY_ID=AKIAxxxxxxxx
export AWS_SECRET_ACCESS_KEY=xxxxxxxxx
export AWS_DEFAULT_REGION=us-east-1
```

---

## Deploy with Terraform

```bash
cd terraform/

# Initialise
terraform init

# Preview
terraform plan

# Deploy
terraform apply
```

---

## Test Lambda Integration

After deployment, upload a file to the origin bucket to trigger the Lambda:

```bash
BUCKET=$(terraform output -raw origin_bucket_name)
aws s3 cp your-file.txt "s3://$BUCKET/"
```

Check Lambda logs in CloudWatch to verify processing.

---

## Outputs

- `origin_bucket_name`: S3 bucket for file uploads
- `audit_bucket_name`: CloudTrail logs destination
- `cloudtrail_name`: CloudTrail trail name
- `lambda_function_name`: S3 event processor function