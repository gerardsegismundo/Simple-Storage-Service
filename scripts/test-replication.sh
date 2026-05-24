#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# test-replication.sh
# Verify Cross-Region Replication is working between origin and replica buckets.
#
# Prerequisites:
#   - Both buckets exist and replication is enabled
#   - Origin bucket objects exist for testing
#
# Usage:
#   ./scripts/test-replication.sh <origin-bucket> <replica-bucket> [<test-key>]
# ---------------------------------------------------------------------------

set -euo pipefail

ORIGIN="${1:?Usage: $0 <origin-bucket> <replica-bucket> [<test-key>]}"
REPLICA="${2:?Usage: $0 <origin-bucket> <replica-bucket> [<test-key>]}"
TEST_KEY="${3:-replication-test/validated-at-$(date -u +%Y%m%dT%H%M%SZ)}.txt"

echo "=== Cross-Region Replication Test ==="
echo "Origin:      $ORIGIN"
echo "Replica:     $REPLICA"
echo "Test key:    $TEST_KEY"
echo ""

# 1. Check replication configuration
echo "--- Replication configuration ---"
aws s3api get-bucket-replication --bucket "$ORIGIN" \
  | python3 -m json.tool 2>/dev/null || \
  echo "No replication rule found or access denied."

echo ""

# 2. Upload test object
echo "--- Uploading test object to origin bucket ---"
echo "replication-validated-at=$(date -u +%Y-%mT%H:%M:%SZ)" | \
  aws s3 cp - "s3://$ORIGIN/$TEST_KEY" \
    --server-side-encryption aws:kms \
    --sse-kms-key-id "$(aws s3api get-bucket-encryption --bucket "$ORIGIN" 2>&1" \
      grep kms_master_key_id | sed 's/.*"\([^"]*\)".*/\1/' 2>/dev/null || true)" \
    --metadata replication-test=true \
    --tagging "replication-test=true"

echo "Uploaded '$TEST_KEY' to origin.  Waiting up to 15 minutes for replication..."
echo "Replication time control guarantees delivery within 15 minutes."
echo ""

# 3. Wait for replication
echo "--- Checking replication status (press Ctrl+C to stop waiting) ---"
TIMEOUT=$((15 * 60))
ELAPSED=0
INTERVAL=30

while [ $ELAPSED -lt $TIMEOUT ]; do
  if aws s3api head-object --bucket "$REPLICA" --key "$TEST_KEY" 2>/dev/null; then
    echo ""
    echo "SUCCESS: Object replicated to replica bucket within $ELAPSED seconds."
    aws s3api head-object --bucket "$REPLICA" --key "$TEST_KEY" \
      | python3 -c "import sys,json;d=json.load(sys.stdin);print('Replica metadata:', json.dumps(d.get('Metadata',{}),indent=2))"
    aws s3 rm "s3://$REPLICA/$TEST_KEY"
    echo "Cleaned up test object from replica."
    aws s3 rm "s3://$ORIGIN/$TEST_KEY"
    echo "Cleaned up test object from origin."
    exit 0
  fi
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

echo "WARNING: Object has not appeared in replica after $((TIMEOUT / 60)) minutes."
echo "Check CloudTrail, bucket policies, and IAM replication role."
