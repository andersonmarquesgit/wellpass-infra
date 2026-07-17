# Wellpass Infra

Repositório GitOps inicial para executar o Wellpass em `dev`, `sit`, `uat` e `prod`.

## Decisão inicial

- **Local/CI:** um cluster `kind`, registry Docker local e Argo CD.
- **Ambientes:** namespaces isolados no mesmo cluster; `prod` deve migrar para cluster/conta separados antes de receber dados reais.
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
```

`make local-down` remove somente o cluster kind chamado `wellpass`; não altera o monorepo da aplicação.

## Antes do primeiro deploy funcional

1. Publicar imagens multi-arch para os seis serviços e para `apps/web`.
2. Substituir os repositórios e tags `REPLACE_ME` nos valores.
3. Definir uma estratégia de migrations versionadas; os SQLs atuais são scripts de inicialização do Compose.
4. Criar `wellpass-secrets` em cada namespace (ou instalar External Secrets/Sealed Secrets).
5. Configurar ingress/DNS/TLS se os ambientes forem expostos fora da máquina.

Veja [docs/assessment.md](docs/assessment.md) para o diagnóstico completo.
Veja [docs/endpoints.md](docs/endpoints.md) para URLs locais, internas e placeholders de produção.
Veja [docs/secrets.md](docs/secrets.md) para o contrato de External Secrets/AWS Secrets Manager.
