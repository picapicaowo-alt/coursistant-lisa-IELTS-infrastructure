#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <release-directory> <output.tgz>" >&2
  exit 64
fi

release_directory=$1
output_archive=$2

if [[ ! -d "$release_directory" ]]; then
  echo "Release directory does not exist: $release_directory" >&2
  exit 66
fi

if [[ ! -x "$release_directory/bin/start" && ! -f "$release_directory/index.html" ]]; then
  echo "Release must contain executable bin/start or frontend index.html" >&2
  exit 67
fi

parent_directory=$(cd "$(dirname "$release_directory")" && pwd)
release_name=$(basename "$release_directory")
output_parent=$(cd "$(dirname "$output_archive")" && pwd)
output_path="$output_parent/$(basename "$output_archive")"

tar \
  --create \
  --gzip \
  --file "$output_path" \
  --directory "$parent_directory/$release_name" \
  .

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$output_path"
else
  shasum -a 256 "$output_path"
fi
