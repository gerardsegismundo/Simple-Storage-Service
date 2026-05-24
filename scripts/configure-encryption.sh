#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# configure-encryption.sh
# Verify KMS and SSE-KMS configuration on the primary S3 bucket.
#
# Usage:
#   ./scripts/configure-encryption.sh <bucket-name>
# ---------------------------------------------------------------------------

set -euo pipefail

BUCKET="${1:?Usage: $0 <bucket-name>}"

echo "=== Encryption configuration for bucket: $BUCKET ==="

ENC=$(aws s3api get-bucket-encryption --bucket "$BUCKET" 2>&1) || {
  echo "No encryption configured or access denied:"
  echo "$ENC"
  exit 1
}

echo "$ENC" | python3 -m json.tool 2>/dev/null || echo "$ENC"

echo ""
echo "Default encryption is now managed by Terraform via aws_s3_bucket.server_side_encryption_configuration."
echo "Use this script only for manual auditing."
