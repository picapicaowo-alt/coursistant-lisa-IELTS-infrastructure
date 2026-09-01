#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <name-prefix>" >&2
  exit 64
fi

name_prefix=$1
aws_region=${AWS_REGION:-ap-northeast-1}

if [[ ! "$name_prefix" =~ ^[a-z0-9-]+$ ]]; then
  echo "Invalid name prefix" >&2
  exit 65
fi

parameters=$(jq -cn '{commands:["sudo /usr/local/bin/coursistant-rollback-backend"]}')
command_id=$(aws ssm send-command \
  --region "$aws_region" \
  --document-name AWS-RunShellScript \
  --targets "Key=tag:Name,Values=$name_prefix-application" \
  --parameters "$parameters" \
  --max-concurrency 1 \
  --max-errors 0 \
  --comment "Rollback Coursistant backend" \
  --query 'Command.CommandId' \
  --output text)

echo "Backend rollback started with SSM command: $command_id"
