#!/bin/sh
set -eu

management_context="${ARGOCD_MANAGEMENT_CONTEXT:-kind-wellpass}"
management_network="${ARGOCD_MANAGEMENT_NETWORK:-kind}"

for dependency in docker kubectl; do
  command -v "$dependency" >/dev/null 2>&1 || {
    echo "Dependência ausente: $dependency" >&2
    exit 1
  }
done

kubectl --context "$management_context" get namespace argocd >/dev/null

connect_management_network() {
  container="$1"
  if ! docker inspect --format '{{json .NetworkSettings.Networks}}' "$container" | grep -q '"'"$management_network"'"'; then
    docker network connect "$management_network" "$container"
  fi
}

kubeconfig_value() {
  container="$1"
  jsonpath="$2"
  docker exec "$container" cat /etc/rancher/k3s/k3s.yaml |
    kubectl config view --kubeconfig=/dev/stdin --raw -o "jsonpath=$jsonpath"
}

register_cluster() {
  name="$1"
  container="$2"
  hostname="$(docker inspect --format '{{.Config.Hostname}}' "$container")"
  server="https://$hostname:6443"
  ca_data="$(kubeconfig_value "$container" '{.clusters[0].cluster.certificate-authority-data}')"
  cert_data="$(kubeconfig_value "$container" '{.users[0].user.client-certificate-data}')"
  key_data="$(kubeconfig_value "$container" '{.users[0].user.client-key-data}')"
  config="{\"tlsClientConfig\":{\"insecure\":false,\"caData\":\"$ca_data\",\"certData\":\"$cert_data\",\"keyData\":\"$key_data\"}}"

  kubectl --context "$management_context" -n argocd create secret generic "cluster-$name" \
    --from-literal=name="$name" \
    --from-literal=server="$server" \
    --from-literal=config="$config" \
    --dry-run=client -o yaml |
    kubectl --context "$management_context" label --local -f - \
      argocd.argoproj.io/secret-type=cluster -o yaml |
    kubectl --context "$management_context" apply -f -
}

bootstrap_environment() {
  container="$1"
  env="$2"
  namespace="wellpass-$env"

  kubectl kustomize "platform/overlays/$env" |
    docker exec -i "$container" kubectl apply -f -

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
      --dry-run=client -o yaml |
      docker exec -i "$container" kubectl apply -f -
  done
}

non_prod_container=floci-eks-wellpass-non-prod
prod_container=floci-eks-wellpass-prod

connect_management_network "$non_prod_container"
connect_management_network "$prod_container"
register_cluster wellpass-non-prod "$non_prod_container"
register_cluster wellpass-prod "$prod_container"

for env in dev sit uat; do
  bootstrap_environment "$non_prod_container" "$env"
done
bootstrap_environment "$prod_container" prod

kubectl --context "$management_context" apply -f argocd/platform-applicationset.yaml
kubectl --context "$management_context" apply -f argocd/applicationset.yaml

echo "Clusters Floci registrados no Argo CD; workloads Kind preservados como fallback."
