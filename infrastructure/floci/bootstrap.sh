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
create_cluster() {
  account="$1"; cluster="$2"
  aws_local "$account" eks describe-cluster --name "$cluster" >/dev/null 2>&1 ||
  aws_local "$account" eks create-cluster --name "$cluster" --role-arn "arn:aws:iam::$account:role/WellpassEksCluster" --resources-vpc-config subnetIds=subnet-local >/dev/null
}
create_cluster 111111111111 wellpass-non-prod
create_cluster 222222222222 wellpass-prod
for account in 111111111111 222222222222; do
  aws_local "$account" ecr describe-repositories --repository-names wellpass >/dev/null 2>&1 ||
  aws_local "$account" ecr create-repository --repository-name wellpass >/dev/null
done
echo "Floci accounts ready: non-prod=111111111111 prod=222222222222"
