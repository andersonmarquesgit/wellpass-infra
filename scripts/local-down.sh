#!/bin/sh
set -eu

cluster="${1:-wellpass}"
management_network="${ARGOCD_MANAGEMENT_NETWORK:-kind}"
runtime_containers="floci-eks-wellpass-non-prod floci-eks-wellpass-prod floci-ecr-registry"

for dependency in docker kind; do
  command -v "$dependency" >/dev/null 2>&1 || {
    echo "Dependência ausente: $dependency" >&2
    exit 1
  }
done

for container in $runtime_containers; do
  if docker inspect "$container" >/dev/null 2>&1; then
    docker network disconnect "$management_network" "$container" >/dev/null 2>&1 || true
    docker stop "$container" >/dev/null
    echo "Container preservado e parado: $container"
  fi
done

if kind get clusters | grep -qx "$cluster"; then
  kind delete cluster --name "$cluster"
else
  echo "Cluster Kind ausente: $cluster"
fi

docker compose -f infrastructure/floci/compose.yaml stop
echo "Laboratório local desligado; containers, redes e volumes Floci preservados."
