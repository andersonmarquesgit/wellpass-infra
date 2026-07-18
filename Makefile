SHELL := /bin/sh
CLUSTER ?= wellpass

.PHONY: local-up local-down validate render argocd-bootstrap floci-argocd

local-up:
	./scripts/local-up.sh $(CLUSTER)

local-down:
	./scripts/local-down.sh $(CLUSTER)

validate:
	kubectl kustomize platform/overlays/dev >/dev/null
	helm lint charts/wellpass -f environments/common.yaml -f environments/dev/values.yaml
	helm template wellpass charts/wellpass -f environments/common.yaml -f environments/dev/values.yaml >/dev/null

render:
	mkdir -p .rendered
	kubectl kustomize platform/overlays/dev > .rendered/platform-dev.yaml
	helm template wellpass charts/wellpass -f environments/common.yaml -f environments/dev/values.yaml > .rendered/apps-dev.yaml

argocd-bootstrap:
	kubectl apply --server-side --force-conflicts -k argocd/bootstrap
	kubectl apply -f argocd/platform-applicationset.yaml
	kubectl apply -f argocd/applicationset.yaml

floci-argocd:
	./scripts/register-floci-clusters.sh
