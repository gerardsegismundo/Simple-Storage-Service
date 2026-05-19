# Simple Storage Service (S3) Project

## Overview

A production-grade, secure, and highly available static content delivery platform built on AWS S3. This project demonstrates advanced S3 features including versioning, encryption, replication, and lifecycle management, combined with Lambda integration for automated processing.

## 📋 Project Goals

- **Deep Dive into S3 Security**: Implement KMS encryption, bucket keys, and access controls
- **High Availability & Performance**: Configure replication and multi-region failover
- **Advanced Data Management**: Versioning, MFA Delete, and lifecycle policies
- **Compliance & Security**: Object Lock, audit logging, and disaster recovery
- **Automated Processing**: Lambda-based event-driven architecture for content processing

## ✨ Key Features

### Core S3 Functionality
- **Static Website Hosting**: Direct S3-based web hosting with custom domain support
- **Versioning & MFA Delete**: Track object history with secure deletion protection
- **Object Lock**: Compliance and governance modes for regulatory requirements

### Security & Encryption
- **KMS Encryption**: Customer-managed key encryption for sensitive data
- **Bucket Keys**: Optimized encryption for cost and performance
- **Access Control**: IAM policies, bucket policies, and ACLs
- **Pre-signed URLs**: Secure, time-limited access to protected objects

### Advanced Features
- **Access Points**: Simplified access management with account-level or multi-account configurations
- **S3 Replication**: Cross-region replication for disaster recovery
- **Lifecycle Policies**: Automated transitions to Glacier, Intelligent-Tiering, or deletion
- **Event Notifications**: Trigger Lambda functions on object upload/modification

### Disaster Recovery & Compliance
- **Cross-Region Replication**: Automatic backup to secondary regions
- **Backup & Restore**: Point-in-time recovery capabilities
- **Audit Logging**: CloudTrail integration for compliance and monitoring
- **Performance Optimization**: Intelligent-Tiering and accelerated transfers

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    S3 Static Website                         │
│                     (Origin Bucket)                          │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Versioning + MFA Delete Enabled                      │  │
│  │ KMS Encryption (Bucket Keys)                         │  │
│  │ Object Lock (Compliance Mode)                        │  │
│  │ CloudTrail Logging Enabled                           │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────┬──────────────────────────────────────┐ │
│  │ Access Points  │   Lifecycle Policies                 │ │
│  │ - Account-wide │   - Intelligent-Tiering              │ │
│  │ - Cross-region │   - Glacier Transition               │ │
│  │                │   - Auto-deletion (Non-compliance)   │ │
│  └────────────────┴──────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                           │
                           ├─→ S3 Events
                           │   (Object Created/Modified)
                           ▼
                    ┌──────────────┐
                    │    Lambda    │
                    │   Function   │
                    │(Content      │
                    │ Processing)  │
                    └──────────────┘
                           │
                           ▼
          ┌────────────────────────────────┐
          │  CloudWatch Logs & Metrics     │
          │  SNS Notifications             │
          │  DynamoDB (Metadata)           │
          └────────────────────────────────┘
                           │
                           ▼
          ┌────────────────────────────────┐
          │ Cross-Region Replica Bucket    │
          │ (Disaster Recovery)            │
          └────────────────────────────────┘
```

## 📦 Project Structure

```
simple-storage-service/
├── README.md                          # Project documentation
├── terraform/                         # Infrastructure as Code
│   ├── main.tf                       # Primary S3 configuration
│   ├── variables.tf                  # Input variables
│   ├── outputs.tf                    # Terraform outputs
│   ├── kms.tf                        # KMS encryption setup
│   ├── replication.tf                # Cross-region replication
│   ├── lifecycle.tf                  # Lifecycle policies
│   └── terraform.tfvars.example      # Example configuration
├── lambda/                            # Lambda functions
│   ├── image-processor/              # Image resizing & optimization
│   │   ├── handler.py
│   │   ├── requirements.txt
│   │   └── index.py
│   ├── content-validator/            # Content validation & metadata
│   │   ├── handler.py
│   │   └── requirements.txt
│   └── notification-sender/          # SNS notifications
│       ├── handler.py
│       └── requirements.txt
├── scripts/                           # Utility scripts
│   ├── presigned-urls.py            # Generate pre-signed URLs
│   ├── bucket-setup.sh               # Initial bucket configuration
│   ├── enable-versioning.sh          # Enable versioning & MFA Delete
│   ├── configure-encryption.sh       # KMS encryption setup
│   └── test-replication.sh           # Test replication configuration
├── config/                            # Configuration files
│   ├── bucket-policy.json            # Bucket access policy
│   ├── lifecycle-policy.json         # Lifecycle configuration
│   ├── replication-config.json       # Replication rules
│   ├── cors-policy.json              # CORS configuration
│   └── cloudtrail-config.json        # Audit logging setup
├── docs/                              # Detailed documentation
│   ├── SECURITY.md                   # Security best practices
│   ├── SETUP.md                      # Detailed setup guide
│   ├── S3-FEATURES.md               # S3 features deep dive
│   ├── COMPLIANCE.md                 # Compliance & audit
│   ├── DISASTER-RECOVERY.md         # DR procedures
│   └── TROUBLESHOOTING.md            # Common issues & solutions
├── tests/                             # Test suite
│   ├── unit/                         # Unit tests
│   ├── integration/                  # Integration tests
│   └── e2e/                          # End-to-end tests
└── .github/                           # GitHub Actions
    └── workflows/
        ├── deploy.yml                # Deployment pipeline
        ├── test.yml                  # Automated testing
        └── security-scan.yml         # Security scanning
```

## 🚀 Quick Start

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- Terraform >= 1.0
- Python 3.9+ (for Lambda functions and scripts)
- Docker (for local Lambda testing)

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/gerardsegismundo/Simple-Storage-Service.git
   cd simple-storage-service
   ```

2. **Configure Terraform**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Deploy Lambda Functions**
   ```bash
   cd ../lambda/image-processor
   pip install -r requirements.txt
   aws lambda update-function-code --function-name s3-image-processor \
     --zip-file fileb://deployment-package.zip
   ```

5. **Enable MFA Delete**
   ```bash
   aws s3api put-bucket-versioning \
     --bucket <bucket-name> \
     --versioning-configuration Status=Enabled,MFADelete=Enabled \
     --sse-customer-algorithm AES256
   ```

## 🔐 Security Features

### Encryption
- **Server-Side Encryption**: KMS with customer-managed keys
- **Bucket Keys**: Enabled for cost optimization
- **HTTPS Enforcement**: All objects transmitted securely
- **In-Transit Encryption**: TLS 1.2+ required

### Access Control
- **IAM Policies**: Role-based access management
- **Bucket Policies**: Resource-based access control
- **Pre-signed URLs**: Time-limited, scope-limited access
- **Access Points**: Simplified multi-account access patterns

### Compliance
- **MFA Delete**: Prevents accidental deletion without MFA
- **Object Lock**: WORM (Write Once Read Many) enforcement
- **CloudTrail**: Complete audit trail of all API calls
- **Versioning**: Recover from accidental modifications

### Monitoring
- **CloudWatch Metrics**: Real-time S3 metrics
- **S3 Access Logging**: Detailed access logs
- **CloudTrail Logs**: API activity and compliance logging
- **AWS Config**: Configuration compliance tracking

## 🔄 Replication & Disaster Recovery

### Cross-Region Replication
- Automatic replication to secondary region(s)
- Configurable replication rules (filters, storage class)
- Replication Time Control (RTC) for guaranteed delivery times
- Replication Metrics & Notifications

### Backup & Recovery
- Point-in-time recovery with versioning
- Batch restore operations
- Cross-region failover procedures
- Recovery Time Objective (RTO) < 1 hour
- Recovery Point Objective (RPO) < 15 minutes

## 📊 Lifecycle Management

### Policy Configuration
- **Intelligent-Tiering**: Automatic cost optimization
- **Glacier Transition**: Archive infrequently accessed objects (30+ days)
- **Deep Archive**: Long-term retention (90+ days)
- **Expiration**: Automatic deletion (365+ days)
- **Non-current Version Deletion**: Cleanup old versions (90 days)

### Cost Optimization
- Intelligent-Tiering for unpredictable access patterns
- Glacier storage for compliance/archival
- Lifecycle policies reduce operational overhead
- Estimated monthly savings: 40-60% for mixed workloads

## 🤖 Lambda Integration

### Event-Driven Architecture
- **S3:ObjectCreated** triggers image processing
- **S3:ObjectRemoved** triggers cleanup
- **S3:ObjectRestore** triggers validation

### Processors
- **Image Processor**: Resize, optimize, and generate thumbnails
- **Content Validator**: Validate file types, virus scanning
- **Notification Sender**: SNS alerts on important events

### Configuration
```json
{
  "EventBridgeConfiguration": {
    "EventBridgeEnabled": true
  },
  "LambdaFunctionConfigurations": [
    {
      "LambdaFunctionArn": "arn:aws:lambda:region:account:function:s3-image-processor",
      "Events": ["s3:ObjectCreated:*"],
      "Filter": {
        "Key": {
          "FilterRules": [
            {"Name": "prefix", "Value": "uploads/"},
            {"Name": "suffix", "Value": ".jpg"}
          ]
        }
      }
    }
  ]
}
```

## 🛠️ Using Pre-signed URLs

Generate time-limited access URLs for secure content delivery:

```bash
python scripts/presigned-urls.py \
  --bucket my-bucket \
  --key path/to/object \
  --expiration 3600 \
  --http-method GET
```

Example Python usage:
```python
import boto3
from datetime import datetime, timedelta

s3_client = boto3.client('s3')

url = s3_client.generate_presigned_url(
    'get_object',
    Params={'Bucket': 'my-bucket', 'Key': 'path/to/object'},
    ExpiresIn=3600,  # 1 hour
)
print(f"Pre-signed URL (expires in 1 hour): {url}")
```

## 📈 Monitoring & Metrics

### CloudWatch Metrics
- BucketSizeBytes
- NumberOfObjects
- AllStorageType
- Replication metrics
- Request count and latency

### Alarms
- Replication failure detection
- Unusual access patterns
- High request rates
- Storage threshold breaches

### Dashboards
Create custom CloudWatch dashboards to monitor:
- Storage usage trends
- Request patterns
- Replication lag
- Cost metrics

## 📝 Testing

### Unit Tests
```bash
cd tests
pytest unit/ -v
```

### Integration Tests
```bash
pytest integration/ -v --aws-profile default
```

### End-to-End Tests
```bash
pytest e2e/ -v --live-aws
```

## 🔍 Troubleshooting

Common issues and solutions:
- **Replication lag**: Check network connectivity and bucket policies
- **Access denied errors**: Verify IAM policies and bucket policies
- **Encryption issues**: Confirm KMS key permissions
- **Lambda timeout**: Increase timeout or optimize code

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for detailed solutions.

## 📚 Documentation

- [Security Best Practices](docs/SECURITY.md)
- [Detailed Setup Guide](docs/SETUP.md)
- [S3 Features Deep Dive](docs/S3-FEATURES.md)
- [Compliance & Auditing](docs/COMPLIANCE.md)
- [Disaster Recovery](docs/DISASTER-RECOVERY.md)

## 🔗 Resources

- [AWS S3 User Guide](https://docs.aws.amazon.com/s3/)
- [S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/BestPractices.html)
- [S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [S3 Versioning Guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
- [S3 Replication Guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📋 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

- **Gerard Segismundo** - [GitHub](https://github.com/gerardsegismundo)

## 🙏 Acknowledgments

- AWS S3 documentation and best practices
- Community contributors and security researchers
- Open-source tools and libraries used in this project

## 📞 Support

For questions or issues:
- Open an issue on GitHub
- Contact: [your-email@example.com]
- AWS Support: Contact your AWS account manager

---

**Last Updated**: May 19, 2026
**Project Status**: Active Development
