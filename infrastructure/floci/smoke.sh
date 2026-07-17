#!/bin/sh
set -eu
endpoint="${AWS_ENDPOINT_URL:-http://localhost:4566}"
region="${AWS_DEFAULT_REGION:-us-east-1}"
for account_cluster in 111111111111:wellpass-non-prod 222222222222:wellpass-prod; do
  account="${account_cluster%%:*}"
  cluster="${account_cluster#*:}"
  AWS_ACCESS_KEY_ID="$account" AWS_SECRET_ACCESS_KEY=test \
    aws --endpoint-url "$endpoint" --region "$region" eks describe-cluster --name "$cluster" \
    --query 'cluster.status' --output text
done
echo "Floci multi-account EKS smoke passed"
