#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <https-base-url>" >&2
  exit 64
fi

base_url=${1%/}
backend_health_path=${BACKEND_HEALTH_PATH:-/api/health}

if [[ ! "$base_url" =~ ^https:// ]]; then
  echo "Base URL must use HTTPS" >&2
  exit 65
fi

temporary_headers=$(mktemp)
trap 'rm -f "$temporary_headers"' EXIT

curl --fail --silent --show-error --max-time 15 \
  --dump-header "$temporary_headers" \
  "$base_url/infra-health" \
  | jq -e '.status == "ok" and .component == "edge"' >/dev/null

grep -Eiq '^x-content-type-options:[[:space:]]*nosniff' "$temporary_headers"
grep -Eiq '^x-frame-options:[[:space:]]*SAMEORIGIN' "$temporary_headers"

curl --fail --silent --show-error --max-time 15 "$base_url$backend_health_path" >/dev/null

echo "Infrastructure and backend smoke checks passed for $base_url"
