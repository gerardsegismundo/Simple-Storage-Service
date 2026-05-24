#!/usr/bin/env bash
# Enable MFA Delete on the primary S3 bucket.
#
# IMPORTANT:
#   MFA Delete cannot be set via Terraform or the Management Console —
#   it requires an AWS CLI call with an MFA session token.
#
# Usage:
#   ./scripts/mfa-setup.sh \
#     <bucket-name> \
#     <root-iam-user-mfa-serial-number> \
#     <6-digit-mfa-token-code>
#
# Example:
#   ./scripts/mfa-setup.sh \
#     simple-storage-service-bucket \
#     arn:aws:iam::866934333672:mfa/root-account-mfa-device \
#     123456
#
# To retrieve your MFA device ARN:
#   aws iam list-mfa-devices --user-name YAD_SYSTEM_010
#
# Prerequisites:
#   - aws cli installed and configured
#   - IAM root user MFA device registered
#   - MFA serial number and a fresh 6-digit token code

set -euo pipefail

BUCKET="$1"
MFA_SERIAL="$2"
TOKEN_CODE="$3"

echo "Enabling MFA Delete on bucket: $BUCKET"
echo "MFA Serial: $MFA_SERIAL"

aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled,MFADelete=Enabled \
  --sse-customer-algorithm AES256 \
  --mfa "$MFA_SERIAL $TOKEN_CODE"

echo "MFA Delete enabled successfully."
