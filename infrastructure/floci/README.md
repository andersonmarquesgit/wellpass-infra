# Floci multi-account lab

O laboratório simula a fronteira entre contas e cria dois EKS locais (k3s),
mas não reproduz SLA, IAM completo, VPC CNI, ALB, latência ou limites AWS.
Kind continua sendo o loop rápido; Floci exercita APIs e automação multi-account.

```bash
docker compose -f infrastructure/floci/compose.yaml up -d
infrastructure/floci/bootstrap.sh
infrastructure/floci/smoke.sh
```

- `111111111111`: non-prod (`wellpass-non-prod`, namespaces dev/sit/uat)
- `222222222222`: prod (`wellpass-prod`, namespace prod)

Floci real mode starts one k3s-backed EKS cluster per account. To use the
native Kubernetes workflow after bootstrap:

```bash
AWS_ENDPOINT_URL=http://localhost:4566 aws eks update-kubeconfig --name wellpass-non-prod
kubectl config get-contexts
```

The emulator validates API shape and a real Kubernetes API, but does not prove
AWS networking, IAM access entries, managed add-ons, ALB behavior, RDS HA, or
service limits. Those remain a disposable AWS sandbox gate before production.

Nunca use essas credenciais fictícias ou o endpoint Floci em AWS real.
