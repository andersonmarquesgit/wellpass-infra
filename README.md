# Wellpass Infra

Repositório GitOps inicial para executar o Wellpass em `dev`, `sit`, `uat` e `prod`.

## Decisão inicial

- **Local/CI:** o cluster `kind` hospeda o Argo CD como management plane.
- **Ambientes:** Floci cria um EKS/k3s non-prod para DEV/SIT/UAT e outro para PROD; o Argo CD registra ambos como destinos externos.
- **Aplicações:** chart Helm reutilizável com valores por ambiente.
- **Plataforma local:** Kustomize para PostgreSQL, RabbitMQ, MongoDB e MailHog.
- **AWS:** emulador opcional; não faz parte do caminho crítico enquanto os serviços não usarem APIs AWS.

## Estrutura

```text
argocd/                 bootstrap e ApplicationSet
charts/wellpass/        chart das aplicações
environments/           valores Helm por ambiente
platform/               base e overlays Kustomize
scripts/                criação/remoção segura do cluster local
docs/                   diagnóstico, arquitetura e custos
```

## Pré-requisitos

Docker, `kubectl`, `kind`, `helm` e acesso às imagens dos serviços. Argo CD é instalado pelo script de bootstrap.

## Fluxo local

```bash
make local-up
make validate
```

Depois de publicar este diretório em um repositório Git, ajuste `repoURL` nos
dois `ApplicationSet` em `argocd/` e execute:

```bash
make argocd-bootstrap
make floci-argocd
```

`make local-down` remove somente o cluster kind chamado `wellpass`; não altera o monorepo da aplicação.

## Ciclo de vida da infraestrutura local

### Subir o laboratório completo

```bash
cd /Users/anderson.marques/Workspace-Go/wellpass-infra

docker compose -f infrastructure/floci/compose.yaml up -d
./infrastructure/floci/bootstrap.sh
make local-up
make argocd-bootstrap
make floci-argocd
```

Essa sequência inicia Floci Core/UI, cria os EKS/k3s non-prod e prod, cria o
Kind, instala o Argo CD e registra os clusters Floci como destinos GitOps.

### Desligar preservando os dados do Floci

```bash
cd /Users/anderson.marques/Workspace-Go/wellpass-infra

make local-down
docker compose -f infrastructure/floci/compose.yaml down
```

O Kind e o Argo CD são removidos. Os volumes persistentes do Floci não são
apagados e podem ser reutilizados na próxima inicialização.

### Remover completamente o laboratório

> **Atenção:** os comandos abaixo removem clusters EKS/k3s, registry local e
> volumes do Floci. Dados locais dos ambientes serão perdidos.

```bash
docker rm -f \
  floci-eks-wellpass-non-prod \
  floci-eks-wellpass-prod \
  floci-ecr-registry

docker compose -f infrastructure/floci/compose.yaml down -v
```

O monorepo `wellpass` e o repositório `wellpass-infra` não são alterados por
nenhuma dessas operações.

## Antes do primeiro deploy funcional

1. Publicar imagens multi-arch para os seis serviços e para `apps/web`.
2. Substituir os repositórios e tags `REPLACE_ME` nos valores.
3. Definir uma estratégia de migrations versionadas; os SQLs atuais são scripts de inicialização do Compose.
4. Criar `wellpass-secrets` em cada namespace (ou instalar External Secrets/Sealed Secrets).
5. Configurar ingress/DNS/TLS se os ambientes forem expostos fora da máquina.

Veja [docs/assessment.md](docs/assessment.md) para o diagnóstico completo.
Veja [docs/endpoints.md](docs/endpoints.md) para URLs locais, internas e placeholders de produção.
Veja [docs/secrets.md](docs/secrets.md) para o contrato de External Secrets/AWS Secrets Manager.

## Nuvem multi-conta

`infrastructure/terraform/organization` cria a fundação da AWS Organization.
Os estados `infrastructure/terraform/live/non-prod` e `live/prod` são
independentes: non-prod hospeda DEV/SIT/UAT no mesmo EKS e prod hospeda apenas
PROD em outro EKS. O apply é deliberadamente manual, com backend S3 separado e
assume-role `WellpassInfrastructureAdmin`.

Antes do primeiro sync cloud, instale External Secrets Operator em cada EKS,
aplique o `argocd/cloud/*-platform-application.yaml` e configure as contas,
região, DNS/TLS e os caminhos `wellpass/<environment>/<service>` no Secrets
Manager. O chart cloud referencia somente `ClusterSecretStore` e nunca contém
valores secretos.

O fluxo de promoção é PR-based: o workflow `promote-image.yml` abre o PR de
DEV após o Go CI e `promote-environment.yml` abre PRs sequenciais DEV→SIT→UAT→PROD,
com GitHub Environments protegidos para os gates humanos.
