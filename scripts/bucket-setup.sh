#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# bucket-setup.sh
# Perform an initial one-time setup of the S3 bucket and related resources.
# This wraps Terraform + post-provisioning steps in a single interface.
#
# Usage:
#   ./scripts/bucket-setup.sh [dev|prod]
# ---------------------------------------------------------------------------

set -euo pipefail

ENV="${1:-dev}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TF_DIR="$PROJECT_ROOT/terraform"
VAR_FILE="$TF_DIR/${ENV}.tfvars"

if [ ! -f "$VAR_FILE" ]; then
  echo "ERROR: Cannot find $VAR_FILE"
  echo "Copy terraform/terraform.tfvars.example to $VAR_FILE and fill in values first."
  exit 1
fi

echo "=== Bucket setup — environment: $ENV ==="

cd "$TF_DIR"

echo "--- Step 1: Terraform init ---"
terraform init -backend=true

echo "--- Step 2: Terraform plan ---"
terraform plan -var-file="$ENV.tfvars"

read -p "Apply the plan? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "--- Step 3: Terraform apply ---"
  terraform apply -auto-approve -var-file="$ENV.tfvars"

  echo "--- Step 4: Enable versioning ---"
  BUCKET=$(terraform output -raw bucket_name 2>/dev/null || echo "$ENV-bucket")
  cd "$PROJECT_ROOT"
  ./scripts/enable-versioning.sh "$BUCKET"

  echo "--- Setup complete ---"
  echo "Run S3_MFA_SERIAL=<serial> S3_MFA_TOKEN=<code> ./scripts/enable-versioning.sh $BUCKET --mfa to enable MFA Delete."
else
  echo "Aborted."
  exit 0
fi
