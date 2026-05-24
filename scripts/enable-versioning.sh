#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# enable-versioning.sh
# Enable versioning (and MFA Delete) on the primary S3 bucket.
#
# MFA Delete requires a live MFA session token — set S3_MFA_SERIAL and
# S3_MFA_TOKEN before calling this script, or it will be skipped.
#
# Usage:
#   ./scripts/enable-versioning.sh <bucket-name> [--mfa]
#
# Without MFA:
#   ./scripts/enable-versioning.sh simple-storage-service-bucket
#
# With MFA Delete:
#   S3_MFA_SERIAL="arn:aws:iam::ACCOUNT:mfa/device" \
#   S3_MFA_TOKEN="012345" \
#   ./scripts/enable-versioning.sh simple-storage-service-bucket --mfa
# ---------------------------------------------------------------------------

set -euo pipefail

BUCKET="${1:?Usage: $0 <bucket-name> [--mfa]}"
ENABLE_MFA=false
if [ "${2:-}" = "--mfa" ]; then
  ENABLE_MFA=true
fi

echo "=== Enabling versioning on bucket: $BUCKET ==="

if [ "$ENABLE_MFA" = true ]; then
  if [ -z "${S3_MFA_SERIAL:-}" ] || [ -z "${S3_MFA_TOKEN:-}" ]; then
    echo "ERROR: S3_MFA_SERIAL and S3_MFA_TOKEN must be set when --mfa is used."
    exit 1
  fi
  echo "MFA Delete will be ENABLED."
  aws s3api put-bucket-versioning \
    --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled,MFADelete=Enabled \
    --mfa "$S3_MFA_SERIAL $S3_MFA_TOKEN"
else
  echo "MFA Delete will NOT be enabled (use --mfa flag to enable)."
  aws s3api put-bucket-versioning \
    --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled
fi

echo "Versioning status:"
aws s3api get-bucket-versioning --bucket "$BUCKET"
echo "Done."
