# Simple Storage Service (S3) — Setup Guide

This guide walks through deploying the **Secure, Highly Available, Versioned Static Content Platform** from a clean terminal session.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Install AWS CLI and Terraform](#install-aws-cli-and-terraform)
3. [Configure AWS Credentials](#configure-aws-credentials)
4. [Create an MFA Device (required for MFA Delete)](#create-an-mfa-device)
5. [Configure Terraform Variables](#configure-terraform-variables)
6. [Deploy with Terraform](#deploy-with-terraform)
7. [Enable MFA Delete](#enable-mfa-delete)
8. [Upload Content & Test Replication](#upload-content--test-replication)
9. [Using Pre-Signed URLs](#using-pre-signed-urls)
10. [Tear Down](#tear-down)

---

## Prerequisites

| Tool | Version |
|---|---|
| Python | 3.9+ |
| Terraform | >= 1.0 (recommended 1.7+) |
| AWS CLI | 2.x |
| GNU bash | 4.4+ (for scripts/) |
| jq | any (optional, for JSON inspection) |

Install dependencies:

```bash
pip install -r lambda/requirements.txt
```

---

## Install AWS CLI and Terraform

### AWS CLI

```bash
# macOS (Homebrew)
brew install awscli

# Ubuntu / Debian
sudo apt-get update && sudo apt-get install -y awscli

# Windows (Chocolatey)
choco install awscli
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

The AWS CLI needs access keys configured locally and the `AWS_REGION` environment variable set:

```bash
aws configure
#   AWS Access Key ID:     AKIAxxxxxxxx
#   AWS Secret Access Key: xxxxxxxxx
#   Default region name:   us-east-1
#   Default output format: json
```

Or set individual environment variables:

```bash
export AWS_ACCESS_KEY_ID=AKIAxxxxxxxx
export AWS_SECRET_ACCESS_KEY=xxxxxxxxx
export AWS_DEFAULT_REGION=us-east-1
```

For GitHub Actions CI/CD, store the same keys in repository secrets:

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS access key ID |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key |
| `TF_STATE_BUCKET_DEV` | S3 bucket for dev Terraform state |
| `TF_STATE_BUCKET_PROD` | S3 bucket for prod Terraform state |

---

## Create an MFA Device (required for MFA Delete)

MFA Delete protects accidental or malicious permanent object deletion. It **cannot** be enabled via Terraform — an API call with a valid MFA session token is required.

1. **Register an MFA virtual device in IAM** (console: IAM → Security credentials → Assigned MFA device):

   ```bash
   aws iam create-virtual-mfa-device \
     --virtual-mfa-device-name s3-mfa \
     --bootstrap-method Base32StringSeed
   ```

2. **Activate it against your IAM user:**

   ```bash
   aws iam enable-mfa-device \
     --user-name YOUR_USER \
     --serial-number arn:aws:iam::ACCT:mfa/s3-mfa \
     --authentication-code-1 CODE1 \
     --authentication-code-2 CODE2
   ```

3. **Save the ARN** — you will pass it as `${MFA_SERIAL}` to `scripts/mfa-setup.sh`.

---

## Configure Terraform Variables

1. Copy the example variable file and fill in your values:

   ```bash
   cd terraform/
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` to match your account:

   ```hcl
   # terraform/terraform.tfvars
   aws_region            = "us-east-1"
   replica_region        = "us-west-2"
   bucket_name           = "simple-storage-service-bucket-unique-suffix"
   replica_bucket_name   = "simple-storage-service-replica-bucket-unique-suffix"
   lambda_function_name  = "simple-storage-service-processor"
   kms_key_alias         = "alias/simple-storage-service-kms"
   
   # Optional — override audit log bucket name (auto-generated if empty)
   audit_logs_bucket_name = ""
   
   # Optional — restrict access point principal to a specific IAM ARN
   s3_access_point_access_principal = "*"
   
   # Required for MFA Delete — leave empty to skip the Terraform null_resource
   mfa_serial_number = ""
   mfa_token_code    = ""
   ```

   > **Global bucket names must be unique** across all AWS accounts. Append a unique
   > suffix if the defaults are already taken.

---

## Deploy with Terraform

```bash
cd terraform/

# 1. Initialise
terraform init

# 2. Preview
terraform plan

# 3. Deploy
terraform apply
```

Apply output will include the following values:

```bash
# Region
terraform output region

# Primary bucket name
terraform output bucket_name

# DR replica bucket name  
terraform output replica_bucket_name

# KMS key ARN
terraform output kms_key_arn

# Lambda function ARN
terraform output lambda_function_arn

# Upload Access Point ARN
terraform output upload_access_point_arn

# Read-only Access Point ARN
terraform output readonly_access_point_arn
```

---

## Enable MFA Delete

After `terraform apply` succeeds, run the MFA setup script with a fresh 6-digit token:

```bash
export S3_MFA_SERIAL="arn:aws:iam::${ACCOUNT_ID}:mfa/your-mfa-device"
export S3_MFA_TOKEN="123456"      # fresh code from your authenticator app

./scripts/mfa-setup.sh \
  "$(terraform -chdir=terraform output -raw bucket_name)" \
  "$S3_MFA_SERIAL" \
  "$S3_MFA_TOKEN"
```

> **Important:** TOTP codes are single-use. Run the command within the 30-second
> window of your authenticator. The script exits cleanly if the token is expired.

Verify:

```bash
./scripts/test-versioning.sh "$(terraform -chdir=terraform output -raw bucket_name)"
```

---

## Upload Content & Test Replication

### Upload to origin bucket

```bash
BUCKET="$(terraform -chdir=terraform output -raw bucket_name)"

aws s3 cp index.html "s3://$BUCKET/" \
  --server-side-encryption aws:kms \
  --sse-kms-key-id "$(terraform -chdir=terraform output -raw kms_key_arn)"
```

### Verify replication

```bash
REPLICA="$(terraform -chdir=terraform output -raw replica_bucket_name)"

# Check that objects are replicating (replication lag < 15 minutes with RTC)
aws s3 ls "s3://$REPLICA/"
```

### Automated replication test

```bash
./scripts/test-replication.sh "$BUCKET" "$REPLICA"
```

---

## Using Pre-Signed URLs

Generate a time-limited URL for secure content delivery:

```bash
python scripts/presigned-urls.py \
  --bucket "$BUCKET" \
  --key index.html \
  --expiration 3600 \
  --http-method GET \
  --region us-east-1
```

For uploads:

```bash
python scripts/presigned-urls.py \
  --bucket "$BUCKET" \
  --key uploads/my-image.jpg \
  --expiration 600 \
  --http-method PUT \
  --region us-east-1
```

---

## CloudTrail / S3 Server Access Logging

The Terraform deployment automatically provisions:

- **`audit_logs_bucket_name`** — dedicated S3 bucket for CloudTrail logs (auto-generated unique name unless overridden)
- **`cloudtrail_name`** — multi-region trail logging to the audit bucket (outputs.cloudtrail_name)
- **Server-access logging** — enabled on the origin bucket (`s3-origin-logs/` prefix in the audit bucket)

View the audit trail name:

```bash
terraform -chdir=terraform output cloudtrail_name
```

---

## Tear Down

```bash
cd terraform
terraform destroy

# If MFA Delete was enabled, you must also disable it before the bucket can be destroyed
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Suspended,MFADelete=Disabled \
  --mfa "$S3_MFA_SERIAL $S3_MFA_TOKEN"
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `BucketAlreadyExists` | Append a unique suffix to `bucket_name` / `replica_bucket_name` |
| `AccessDenied` for replication | Confirm the replication IAM role has the required KMS permissions |
| MFA Delete `token expired` | Generate a fresh 6-digit code and re-run immediately |
| CloudTrail `TrailAlreadyExistsException` | The account may already have a trail named `s3-service-audit-trail`; rename the resource in `cloudtrail.tf` |
| Lambda timeout | Increase `timeout` in `aws_lambda_function.s3_event_processor` in `main.tf` |

For more, see GitHub Issues.
