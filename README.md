# Simple Storage Service (S3) Project

## Overview

A clean, minimal AWS architecture demonstrating S3, Lambda, and CloudTrail integration suitable for student submissions. This project focuses on core AWS services without requiring elevated IAM permissions.

## ✨ Key Features

### Core Components
- **S3 Origin Bucket**: With versioning, AES256 encryption, and lifecycle rules
- **S3 Audit Bucket**: CloudTrail logging destination
- **Lambda Function**: Triggered by S3 upload events for simple processing
- **CloudTrail**: API activity logging to audit bucket
- **Minimal IAM**: Basic Lambda execution role with least privilege

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    S3 Origin Bucket                          │
│  - Versioning enabled                                      │
│  - AES256 encryption                                       │
│  - Lifecycle rules (30 days → STANDARD_IA, 365 days NC → delete)│
└────────────────────────────────────────────────────────────┘
                            │
                            ├─→ S3 Events (ObjectCreated)
                            ▼
                     ┌──────────────┐
                     │    Lambda    │
                     │  (Python)    │
                     └──────────────┘
                            │
                            ▼
           ┌────────────────────────────────┐
           │  CloudWatch Logs (basic exec)│
           └────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│                    CloudTrail                                │
│         Logging to S3 Audit Bucket                           │
└────────────────────────────────────────────────────────────┘
```

## 📦 Project Structure

```
simple-storage-service/
├── terraform/
│   └── main.tf              # All infrastructure as code
├── lambda/
│   └── s3_event_processor.py  # Lambda handler for S3 events
├── tests/
│   └── test_smoke.py        # Configuration validation tests
└── .github/workflows/
    └── main.yaml            # CI/CD pipeline
```

## 🚀 Quick Start

### Prerequisites
- AWS Account with basic S3/Lambda/CloudTrail permissions
- Terraform >= 1.0
- Python 3.11

### Deploy

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Test Lambda

Upload a file to the origin bucket - the Lambda will automatically process the event.

## 🧪 Testing

```bash
# Run validation tests
pytest tests/ -v
```

## 🔒 Security

- **No ACLs**: Uses IAM policies and bucket policies
- **AES256 Encryption**: Server-side encryption enabled
- **Public Access Blocked**: All public access blocked on both buckets
- **Minimal IAM**: Lambda role attaches only `AWSLambdaBasicExecutionRole`

## 📋 Outputs

- `origin_bucket_name`: The S3 bucket for file uploads
- `audit_bucket_name`: CloudTrail logs destination
- `cloudtrail_name`: CloudTrail trail name
- `lambda_function_name`: S3 event processor function