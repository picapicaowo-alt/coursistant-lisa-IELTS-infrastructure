#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <secret-arn-or-name> <secret.json>" >&2
  exit 64
fi

secret_id=$1
secret_file=$2
aws_region=${AWS_REGION:-ap-northeast-1}

if [[ ! -f "$secret_file" ]]; then
  echo "Secret file not found: $secret_file" >&2
  exit 66
fi

file_mode=$(stat -f '%Lp' "$secret_file" 2>/dev/null || stat -c '%a' "$secret_file")
if [[ "$file_mode" != "600" && "$file_mode" != "400" ]]; then
  echo "Secret file must have mode 0600 or 0400" >&2
  exit 65
fi

if ! jq -e 'type == "object" and all(keys[]; test("^[A-Z][A-Z0-9_]*$"))' "$secret_file" >/dev/null; then
  echo "Secret must be a JSON object with uppercase environment-style keys" >&2
  exit 65
fi

if jq -e 'keys[] | select(test("PASSWORD|SECRET|TOKEN|API_KEY|PRIVATE_KEY"))' "$secret_file" >/dev/null; then
  : # Sensitive keys are expected here; values are never printed.
fi

aws secretsmanager put-secret-value \
  --region "$aws_region" \
  --secret-id "$secret_id" \
  --secret-string "file://$secret_file" \
  --query 'ARN' \
  --output text >/dev/null

echo "Secret value stored without printing its contents."
