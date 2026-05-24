#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# test-versioning.sh
# Quick smoke-test that verifies versioning + MFA Delete state on a bucket.
#
# Usage:
#   ./scripts/test-versioning.sh <bucket-name>
# ---------------------------------------------------------------------------

set -euo pipefail

BUCKET="${1:?Usage: $0 <bucket-name>}"

echo "=== Checking versioning on bucket: $BUCKET ==="

VERSIONING=$(aws s3api get-bucket-versioning --bucket "$BUCKET" 2>&1) || {
  echo "ERROR: Cannot access bucket versioning: $VERSIONING"
  exit 1
}

STATUS=$(echo "$VERSIONING" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('Status', 'Disabled'))
" 2>/dev/null || echo "$VERSIONING")

MFA_STATUS=$(echo "$VERSIONING" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('MFADelete', 'Disabled'))
" 2>/dev/null || echo "Disabled")

echo "Versioning:            $STATUS"
echo "MFA Delete:            $MFA_STATUS"
echo ""

if [ "$STATUS" = "Enabled" ]; then
  echo "OK: Versioning is enabled."
else
  echo "FAIL: Versioning is NOT enabled."
  exit 1
fi

if [ "$MFA_STATUS" = "Enabled" ]; then
  echo "OK: MFA Delete is enabled."
else
  echo "INFO: MFA Delete is currently $MFA_STATUS."
  echo "      Run: ./scripts/mfa-setup.sh $BUCKET <MFA_SERIAL> <TOKEN>"
fi
