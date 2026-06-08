#!/bin/bash
set -eu

cd "$(dirname "$0")/../terraform"

PROJECT_NAME="${1:-${PROJECT_NAME:-s3-platform}}"

ROLES=(
  "${PROJECT_NAME}-lambda-role"
  "${PROJECT_NAME}-replication-role"
)

TF_RESOURCES=(
  "aws_iam_role.lambda"
  "aws_iam_role.replication"
)

for i in "${!ROLES[@]}"; do
  if ! terraform state show "${TF_RESOURCES[$i]}" >/dev/null 2>&1; then
    echo "Importing ${TF_RESOURCES[$i]} → ${ROLES[$i]}"
    if ! terraform import "${TF_RESOURCES[$i]}" "${ROLES[$i]}"; then
      echo "Import failed — resource may not exist yet, letting terraform apply handle it"
    fi
  else
    echo "${TF_RESOURCES[$i]} already in state, skipping"
  fi
done
