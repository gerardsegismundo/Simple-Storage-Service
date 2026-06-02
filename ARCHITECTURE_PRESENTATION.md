# Simple Storage Service - Architecture Presentation

## Project Overview

A clean, minimal AWS architecture demonstrating S3 and Lambda integration for automated file processing.

---

## 🏗️ Architecture Diagram

```
┌────────────────────────────────────────────────────────────┐
│                    S3 Origin Bucket                          │
│  - Versioning enabled                                      │
│  - Unique timestamp suffix                                 │
│  - Force destroy for easy cleanup                            │
└────────────────────────────────────────────────────────────┘
                             │
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

---

## 📋 Components Breakdown

### 1. S3 Bucket (`terraform/s3.tf`)
- **Primary Bucket**: Creates an S3 bucket with unique naming using timestamp suffix
- **Versioning**: Enabled to track and maintain all object versions
- **Configuration**: Encryption (commented), Lifecycle rules (commented), Public Access Block (commented) - ready for uncommenting for production use

### 2. Lambda Function (`lambda/s3_event_processor.py`)
- **Handler**: `lambda_handler` function processes S3 events
- **Event Processing**: Iterates through S3 event records and extracts bucket/key information
- **Output**: Returns HTTP 200 response with JSON message

### 3. Terraform Infrastructure (`terraform/`)
- **main.tf**: Provider configuration (AWS + Archive providers)
- **variables.tf**: Configurable variables (project_name, primary_region)
- **outputs.tf**: Exports `primary_bucket` ID after deployment
- **lambda.tf**: IAM roles, Lambda function, S3 notifications (commented)
- **replication.tf**: Cross-region replication configuration (commented)

### 4. CI/CD Pipeline (`.github/workflows/main.yaml`)
- **5 Stages**: Build → Test → Validate → Deploy Dev → Deploy Staging → Deploy Prod
- **Build**: Terraform format check
- **Test**: Pytest validation
- **Validate**: Terraform syntax validation
- **Deploy**: Multi-environment deployment with approval gates

---

## 🔧 How It Works

1. **Deploy**: Run `terraform apply` to create S3 bucket and Lambda infrastructure
2. **Upload**: When a file is uploaded to the S3 bucket, an event is triggered
3. **Process**: Lambda function (`s3_event_processor.py`) receives the event and logs the bucket/key details
4. **Monitor**: All logs are automatically sent to CloudWatch for debugging and monitoring

---

## 🚀 Quick Start

```bash
cd terraform
terraform init
terraform apply
```

---

## 🧪 Testing

```bash
pytest tests/ -v
```

---

## 🔒 Security Features (Available)

- **Versioning**: Protects against accidental deletions
- **IAM Role**: Template for least-privilege Lambda execution role
- **Basic Execution Role**: Attaches `AWSLambdaBasicExecutionRole` policy

---

## 📁 Project Structure

```
simple-storage-service/
├── terraform/
│   ├── main.tf          # Provider & version config
│   ├── s3.tf            # S3 bucket definition
│   ├── lambda.tf        # Lambda + IAM (commented)
│   ├── variables.tf     # Input variables
│   ├── outputs.tf       # Output values
│   └── replication.tf   # Replication config (commented)
├── lambda/
│   └── s3_event_processor.py
├── tests/
│   └── test_smoke.py
└── .github/workflows/main.yaml
```