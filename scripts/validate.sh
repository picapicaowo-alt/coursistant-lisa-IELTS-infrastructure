#!/usr/bin/env bash
set -euo pipefail

repository_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repository_root"

terraform fmt -check -recursive

for directory in bootstrap environments/test; do
  terraform -chdir="$directory" init -backend=false -input=false >/dev/null
  terraform -chdir="$directory" validate
done

terraform -chdir=environments/test test

if command -v tflint >/dev/null 2>&1; then
  for directory in bootstrap environments/test; do
    tflint --chdir="$directory" --init
    tflint --chdir="$directory"
  done
fi

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck scripts/*.sh
fi

if command -v checkov >/dev/null 2>&1; then
  checkov -d . --framework terraform --compact --quiet
fi

if command -v actionlint >/dev/null 2>&1; then
  actionlint
fi

echo "Infrastructure validation passed."
