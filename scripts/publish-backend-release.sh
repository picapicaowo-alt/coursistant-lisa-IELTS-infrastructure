#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 || $# -gt 5 ]]; then
  echo "Usage: $0 <name-prefix> <artifact-bucket> <release.tgz> <release-id> [sha256]" >&2
  exit 64
fi

name_prefix=$1
artifact_bucket=$2
archive=$3
release_id=$4
expected_sha=${5:-}
aws_region=${AWS_REGION:-ap-northeast-1}

if [[ ! "$name_prefix" =~ ^[a-z0-9-]+$ ]] || [[ ! "$release_id" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,95}$ ]]; then
  echo "Invalid name prefix or release ID" >&2
  exit 65
fi

if [[ ! -f "$archive" ]]; then
  echo "Archive not found: $archive" >&2
  exit 66
fi

if [[ -z "$expected_sha" ]]; then
  if command -v sha256sum >/dev/null 2>&1; then
    expected_sha=$(sha256sum "$archive" | awk '{print $1}')
  else
    expected_sha=$(shasum -a 256 "$archive" | awk '{print $1}')
  fi
fi

if [[ ! "$expected_sha" =~ ^[a-fA-F0-9]{64}$ ]]; then
  echo "Invalid SHA-256" >&2
  exit 65
fi

aws sts get-caller-identity >/dev/null

s3_uri="s3://$artifact_bucket/releases/backend/$release_id.tgz"
aws s3 cp --region "$aws_region" --only-show-errors "$archive" "$s3_uri"

instance_ids=$(aws ec2 describe-instances \
  --region "$aws_region" \
  --filters \
    "Name=tag:Name,Values=$name_prefix-application" \
    "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

if [[ -z "$instance_ids" ]]; then
  echo "No running application instance found for $name_prefix" >&2
  exit 69
fi

printf -v remote_command 'sudo /usr/local/bin/coursistant-deploy-backend %q %q %q' \
  "$s3_uri" "$expected_sha" "$release_id"
parameters=$(jq -cn --arg command "$remote_command" '{commands:[$command]}')

command_id=$(aws ssm send-command \
  --region "$aws_region" \
  --document-name AWS-RunShellScript \
  --targets "Key=tag:Name,Values=$name_prefix-application" \
  --parameters "$parameters" \
  --max-concurrency 1 \
  --max-errors 0 \
  --comment "Deploy Coursistant backend $release_id" \
  --query 'Command.CommandId' \
  --output text)

for _ in $(seq 1 90); do
  statuses=$(aws ssm list-command-invocations \
    --region "$aws_region" \
    --command-id "$command_id" \
    --query 'CommandInvocations[].Status' \
    --output text)

  if [[ -n "$statuses" ]] && ! grep -Eq 'Pending|InProgress|Delayed' <<<"$statuses"; then
    if grep -Eq 'Failed|Cancelled|TimedOut|Cancelling' <<<"$statuses"; then
      aws ssm list-command-invocations --region "$aws_region" --command-id "$command_id" --details
      exit 70
    fi
    echo "Backend release deployed: $release_id"
    exit 0
  fi
  sleep 5
done

echo "Timed out waiting for SSM command $command_id" >&2
exit 71
