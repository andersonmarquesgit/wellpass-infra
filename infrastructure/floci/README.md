# Floci multi-account lab

O laboratório simula a fronteira entre contas e cria dois EKS locais (k3s),
mas não reproduz SLA, IAM completo, VPC CNI, ALB, latência ou limites AWS.
Kind continua sendo o loop rápido; Floci exercita APIs e automação multi-account.

```bash
docker compose -f infrastructure/floci/compose.yaml up -d
infrastructure/floci/bootstrap.sh
infrastructure/floci/smoke.sh
```

Abra o console em <http://localhost:4500>. O container `floci-ui` usa a conta
non-prod (`111111111111`) como credencial padrão e consulta o Floci pela rede
Docker em `http://floci:4566`. Em **Cloud Explorer → k8s Engine**, a UI lista os
clusters EKS conhecidos pelo emulador.

A UI mantém a conta ativa no armazenamento do navegador e começa em
`000000000000`, mesmo que o backend tenha outra credencial padrão. No seletor
**Account**, informe uma das contas do laboratório e pressione **Switch**:

- `111111111111` mostra `wellpass-non-prod`;
- `222222222222` mostra `wellpass-prod`.

O account ID selecionado é enviado como `x-floci-account-id` e prevalece sobre
a credencial padrão do container. Recursos de contas diferentes nunca aparecem
juntos na mesma consulta.

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

## Floci UI, Argo CD e Kubernetes

Os componentes são complementares:

- Floci emula o plano de controle AWS e cria EKS locais apoiados por k3s.
- Floci UI visualiza os recursos AWS que o Floci conhece, como clusters EKS.
- Argo CD reconcilia os manifests GitOps dentro do Kubernetes alvo.
- Kubernetes executa os workloads, Services, Ingresses e Jobs de migration.

No laboratório, o Argo CD permanece no cluster Kind `kind-wellpass` como
management plane e os EKS simulados são dois clusters k3s independentes. O
registro e o direcionamento dos ambientes são automatizados e idempotentes:

```bash
make floci-argocd
```

O comando conecta os containers k3s à rede `kind`, registra os endpoints TLS e
direciona DEV/SIT/UAT para `wellpass-non-prod` e PROD para `wellpass-prod`.
Namespaces antigos no Kind não são removidos automaticamente e funcionam como
fallback durante a validação.

Se o GHCR estiver privado, as imagens precisam ser carregadas no k3s local ou
um `imagePullSecret` precisa ser criado fora do Git. Nenhuma credencial é
armazenada por esse bootstrap.

A UI não lê o repositório GitOps nem substitui o Argo CD. Alterações OpenTofu
precisam ser aplicadas novamente contra o endpoint Floci. Alterações de Helm,
Kustomize, Argo CD ou release são reconciliadas pelo Argo CD e não exigem
reiniciar o Floci. Alterações no código da aplicação exigem uma nova imagem e
uma nova referência imutável na release; não exigem recriar o cluster.
