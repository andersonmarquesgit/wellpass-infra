#!/bin/sh
set -eu

cluster="${1:-wellpass}"
for dependency in docker kubectl kind; do
  command -v "$dependency" >/dev/null 2>&1 || { echo "Dependência ausente: $dependency" >&2; exit 1; }
done

if ! kind get clusters | grep -qx "$cluster"; then
  kind create cluster --name "$cluster" --config kind/cluster.yaml
fi

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl rollout status --namespace ingress-nginx deployment/ingress-nginx-controller --timeout=180s

for env in dev sit uat prod; do
  namespace="wellpass-$env"
  kubectl apply -k "platform/overlays/$env"
  for pair in authentication-service:users customer-service:customers provider-service:providers wellness-session-service:wellness_sessions notification-service:notifications logger-service:none web:none; do
    service="${pair%%:*}"
    database="${pair#*:}"
    if [ "$database" = none ]; then
      dsn="unused"
    else
      dsn="host=postgres port=5432 user=$database password=local-only dbname=$database sslmode=disable"
    fi
    kubectl create secret generic "$service-secrets" \
      --namespace "$namespace" \
      --from-literal=DSN="$dsn" \
      --from-literal=SECRET_KEY="local-only-change-me" \
      --from-literal=MEMBERSHIP_INTERNAL_TOKEN="local-membership-token" \
      --from-literal=INTERNAL_SERVICE_TOKEN="local-internal-token" \
      --dry-run=client -o yaml | kubectl apply -f -
  done
done

echo "Cluster $cluster criado. Publique as imagens e configure o repoURL antes do sync Argo CD."
