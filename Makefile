SHELL := /bin/sh
CLUSTER ?= wellpass

.PHONY: local-up local-down validate render argocd-bootstrap

local-up:
	./scripts/local-up.sh $(CLUSTER)

local-down:
	kind delete cluster --name $(CLUSTER)

validate:
	kubectl kustomize platform/overlays/dev >/dev/null
	helm lint charts/wellpass -f environments/common.yaml -f environments/dev/values.yaml
	helm template wellpass charts/wellpass -f environments/common.yaml -f environments/dev/values.yaml >/dev/null

render:
	mkdir -p .rendered
	kubectl kustomize platform/overlays/dev > .rendered/platform-dev.yaml
	helm template wellpass charts/wellpass -f environments/common.yaml -f environments/dev/values.yaml > .rendered/apps-dev.yaml

argocd-bootstrap:
	kubectl apply -k argocd/bootstrap
	kubectl apply -f argocd/platform-applicationset.yaml
	kubectl apply -f argocd/applicationset.yaml
