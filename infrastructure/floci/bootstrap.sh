#!/bin/sh
set -eu
endpoint="${AWS_ENDPOINT_URL:-http://localhost:4566}"
region="${AWS_DEFAULT_REGION:-us-east-1}"
create_cluster() {
  account="$1"; cluster="$2"
  AWS_ACCESS_KEY_ID="$account" AWS_SECRET_ACCESS_KEY=test aws --endpoint-url "$endpoint" --region "$region" eks describe-cluster --name "$cluster" >/dev/null 2>&1 ||
  AWS_ACCESS_KEY_ID="$account" AWS_SECRET_ACCESS_KEY=test aws --endpoint-url "$endpoint" --region "$region" eks create-cluster --name "$cluster" --role-arn "arn:aws:iam::$account:role/WellpassEksCluster" --resources-vpc-config subnetIds=subnet-local >/dev/null
}
create_cluster 111111111111 wellpass-non-prod
create_cluster 222222222222 wellpass-prod
for account in 111111111111 222222222222; do
  AWS_ACCESS_KEY_ID="$account" AWS_SECRET_ACCESS_KEY=test aws --endpoint-url "$endpoint" --region "$region" ecr describe-repositories --repository-names wellpass >/dev/null 2>&1 ||
  AWS_ACCESS_KEY_ID="$account" AWS_SECRET_ACCESS_KEY=test aws --endpoint-url "$endpoint" --region "$region" ecr create-repository --repository-name wellpass >/dev/null
done
echo "Floci accounts ready: non-prod=111111111111 prod=222222222222"
