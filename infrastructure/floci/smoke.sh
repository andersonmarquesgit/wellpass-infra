#!/bin/sh
set -eu
endpoint="${AWS_ENDPOINT_URL:-http://localhost:4566}"
region="${AWS_DEFAULT_REGION:-us-east-1}"
aws_local() {
  account="$1"
  shift
  if command -v aws >/dev/null 2>&1; then
    AWS_ACCESS_KEY_ID="$account" AWS_SECRET_ACCESS_KEY=test \
      aws --endpoint-url "$endpoint" --region "$region" "$@"
  else
    docker compose -f infrastructure/floci/compose.yaml exec -T \
      -e AWS_ACCESS_KEY_ID="$account" -e AWS_SECRET_ACCESS_KEY=test \
      floci awslocal --region "$region" "$@"
  fi
}
for account_cluster in 111111111111:wellpass-non-prod 222222222222:wellpass-prod; do
  account="${account_cluster%%:*}"
  cluster="${account_cluster#*:}"
  aws_local "$account" eks describe-cluster --name "$cluster" \
    --query 'cluster.status' --output text
done
curl -fsS http://localhost:4500/ >/dev/null
curl -fsS http://localhost:4500/api/clouds/aws/status >/dev/null
for account_cluster in 111111111111:wellpass-non-prod 222222222222:wellpass-prod; do
  account="${account_cluster%%:*}"
  cluster="${account_cluster#*:}"
  ui_clusters="$(curl -fsS \
    -H "x-floci-account-id: $account" \
    http://localhost:4500/api/clouds/aws/services/k8s/resources)"
  printf '%s' "$ui_clusters" | grep -q "$cluster"
done
echo "Floci multi-account EKS smoke passed"
echo "Floci UI ready at http://localhost:4500"
