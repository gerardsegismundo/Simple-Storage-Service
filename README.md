# Simple Storage Service (S3) Platform

A production-ready AWS infrastructure for static website hosting with automated CI/CD, S3 object processing, and multi-region replication.

## Deploy_dev
<img width="696" height="233" alt="image" src="https://github.com/user-attachments/assets/628fa38c-b590-482b-9273-713e4202c5fe" />

## Deploy_staging
<img width="687" height="225" alt="image" src="https://github.com/user-attachments/assets/235135d4-c1ae-494f-bb47-79606395b4d3" />

## Deploy_prod
<img width="686" height="221" alt="image" src="https://github.com/user-attachments/assets/dc44d04b-4fe0-4b82-8ed2-f6f853922561" />

## Cloudwatch Dashboard
<img width="949" height="398" alt="image" src="https://github.com/user-attachments/assets/478744db-06bf-4667-ba31-a83e537fa12b" />


## ✨ Highlights

- **Automated CI/CD**: Multi-environment deployments with GitHub Actions
- **Static Website**: S3 + CloudFront for fast, secure content delivery
- **Event-Driven Processing**: Lambda triggers on S3 object uploads
- **Multi-Region Replication**: Automatic bucket replication for disaster recovery
- **Security First**: Encryption at rest, public access blocking, dead-letter queues
- **Observability**: CloudWatch alarms with SNS alerting for failures

## 🏗️ ArchitectureHere 
```

┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                       GITHUB REPOSITORY                                        │
│                                    (Simple-Storage-Service)                                    │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
│
▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    GITHUB ACTIONS WORKFLOW                                     │
│                                                                                                │
│    ┌─────────┐    ┌─────────┐    ┌───────────┐    ┌─────────┐    ┌──────────┐                  │
│    │  BUILD  │───▶│  TEST   │───▶│ VALIDATE  │───▶│SECURITY │───▶│  DEPLOY  │                  │
│    │  (fmt)  │    │(pytest) │    │(terraform)│    │(Checkov)│    │   (TF)   │                  │
│    └─────────┘    └─────────┘    └───────────┘    └─────────┘    └──────────┘                  │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
│
▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                         AWS US-EAST-1                                          │
│                                                                                                │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                                     S3 PRIMARY BUCKET                                    │  │
│  │                                  (Static Website Origin)                                 │  │
│  │   ├── Static website hosting (index.html, error.html)                                    │  │
│  │   ├── Versioning enabled                                                                 │  │
│  │   ├── AES256 encryption at rest                                                          │  │
│  │   ├── Lifecycle: 30d → STANDARD_IA, 365d version cleanup                                  │  │
│  │   └── Public access blocked (OAI-only)                                                   │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────┘  │
│            │                             │                             │                       │
│            │ ObjectCreated               │ OriginAccessIdentity        │ Cache Invalidation    │
│            │ Event                       │ (CloudFront)                │                       │
│            ▼                             ▼                             ▼                       │
│  ┌─────────────────┐    ┌─────────────────────────────────┐    ┌───────────────────────────┐   │
│  │     LAMBDA      │    │     CLOUDFRONT DISTRIBUTION     │    │        CLOUDFRONT         │   │
│  │                 │    │                                 │    │    (Cache Invalidate)     │   │
│  │ - Python 3.11   │    │ - OAI for secure S3 access      │    │                           │   │
│  │ - 10 reserved   │    │ - HTTPS redirect enforced       │    │                           │   │
│  │ - DLQ enabled   │    │ - IPv6 enabled                  │    │                           │   │
│  │ - CloudWatch    │    │ - Default certificate           │    │                           │   │
│  └─────────────────┘    └─────────────────────────────────┘    └───────────────────────────┘   │
│            │                             │                                                     │
│            │ Errors                      │                                                     │
│            ▼                             ▼                                                     │
│  ┌─────────────────┐    ┌─────────────────────────────────┐    ┌───────────────────────────┐   │
│  │     SQS DLQ     │    │       CLOUDWATCH METRICS        │    │                           │   │
│  │                 │    │                                 │    │                           │   │
│  │ - KMS encrypted │    │ - Lambda error alarms (SNS)     │    │                           │   │
│  │ - Failure cap.  │    │ - DLQ depth alarm               │    │                           │   │
│  └─────────────────┘    └─────────────────────────────────┘    └───────────────────────────┘   │
│                                          │                                                     │
│                                          └──────────┬──────────────────┐                       │
│                                                     ▼                                          │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                                      SNS ALERTS TOPIC                                    │  │
│  │                                                                                          │  │
│  │    - Email subscription for notifications                                                │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                                      S3 REPLICA BUCKET                                   │  │
│  │                          (Cross-Region Replication Destination)                          │  │
│  │   ├── Versioning enabled                                                                 │  │
│  │   └── Lifecycle: 365d expiration                                                         │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────┘  │
│            ▲                                                                                   │
│            │ Replication                                                                       │
│            └───────────────────────────────────────────────────────────────────────────────────┘
└────────────────────────────────────────────────────────────────────────────────────────────────┘

```

## 📦 Project Structure

```
simple-storage-service/
├── terraform/
│   ├── main.tf              # Provider configuration
│   ├── s3.tf                # Primary/replica buckets, CloudFront, OAI
│   ├── lambda.tf            # Lambda function, IAM role, SNS alerts
│   ├── dlq.tf               # Dead-letter queue for Lambda failures
│   ├── replication.tf       # Cross-region replication config
│   ├── github.tf            # GitHub environment setup
│   ├── outputs.tf           # Terraform outputs
│   ├── variables.tf         # Input variables
│   └── .checkov.yml         # Security scan exclusions
├── lambda/
│   └── s3_event_processor.py # Lambda handler for S3 events
├── tests/
│   └── test_smoke.py        # Smoke tests for validation
├── .github/workflows/
│   └── main.yaml            # CI/CD pipeline (4-stage deployments)
├── index.html               # Static website entry point
├── error.html               # Static website error page
└── .gitleaks.toml           # Secret scanning configuration
```

## 🚀 Quick Start

### Deploy

```bash
cd terraform
terraform init
terraform apply
```

### Test Lambda

Upload a file to the primary bucket - the Lambda will automatically process the event and log to CloudWatch.

## 🧪 Testing

```bash
pytest tests/ -v
```

## 🔒 Security Features

- **AES256 Encryption**: Server-side encryption on all S3 buckets
- **Public Access Blocked**: All public access blocked, OAI-only for CloudFront
- **Dead-Letter Queue**: Failed Lambda invocations routed to SQS
- **Security Scanning**: Checkov + Gitleaks in CI pipeline
- **Branch Protection**: GitHub environments with required reviewers

## 📋 Terraform Outputs

- `primary_bucket`: The S3 bucket for static website hosting
- `replica_bucket`: Cross-region replication destination
- `lambda_function`: S3 event processor function name
- `website_url`: CloudFront HTTPS endpoint
- `cloudfront_distribution_id`: CloudFront distribution ID (for cache invalidation)

## 🌐 Environment Deployments

| Branch | Environment | Trigger |
|--------|-------------|---------|
| `develop` | Development | Auto-deploy on push |
| `staging` | Staging | Auto-deploy on push |
| `main` | Production | Auto-deploy on push |

Each environment deploys the full infrastructure stack with the same configuration.
