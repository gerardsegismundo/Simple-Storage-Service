# Simple Storage Service (S3) Project

<img width="1297" height="400" alt="image" src="https://github.com/user-attachments/assets/299443c7-2169-4162-9f33-be87bd232c09" />


## Overview

A clean, minimal AWS architecture demonstrating S3 and Lambda integration suitable for student submissions.

## ✨ Key Features

### Core Components
- **S3 Bucket**: Versioning enabled, AES256 encryption, lifecycle rules
- **Lambda Function**: Triggered by S3 upload events for simple processing
- **Minimal IAM**: Basic Lambda execution role with least privilege

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    S3 Origin Bucket                          │
│  - Versioning enabled                                      │
│  - AES256 encryption                                       │
│  - Lifecycle rules (30 days → STANDARD_IA, 365 days NC delete)│
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
           │  CloudWatch Logs (auto-created)│
           └────────────────────────────────┘
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

### Deploy

```bash
cd terraform
terraform init
terraform apply
```

### Test Lambda

Upload a file to the origin bucket - the Lambda will automatically process the event.

## 🧪 Testing

```bash
pytest tests/ -v
```

## 🔒 Security

- **No ACLs**: Uses IAM policies only
- **AES256 Encryption**: Server-side encryption enabled
<<<<<<< HEAD
- **Public Access Blocked**: All public access blocked
- **Minimal IAM**: Lambda role attaches only AWSLambdaBasicExecutionRole
=======
- **Public Access Blocked**: All public access blocked on both buckets
- **Minimal IAM**: Lambda role attaches only `AWSLambdaBasicExecutionRole`

## 📋 Outputs

- `origin_bucket_name`: The S3 bucket for file uploads
- `audit_bucket_name`: CloudTrail logs destination
- `cloudtrail_name`: CloudTrail trail name
- `lambda_function_name`: S3 event processor function
>>>>>>> master
