# Diagnóstico e arquitetura recomendada

## Inventário observado no monorepo

| Componente | Runtime | Dependências principais | Estado de empacotamento |
|---|---|---|---|
| authentication-service | Go | PostgreSQL, RabbitMQ, logger | Dockerfile multi-stage |
| customer-service | Go | PostgreSQL, RabbitMQ | Dockerfile multi-stage |
| provider-service | Go | PostgreSQL, RabbitMQ | Dockerfile copia binário local |
| wellness-session-service | Go | PostgreSQL, RabbitMQ, customer | Dockerfile multi-stage |
| notification-service | Go | PostgreSQL, RabbitMQ, SMTP | Dockerfile multi-stage |
| logger-service | Go | MongoDB | Dockerfile multi-stage |
| apps/web | Next.js | APIs HTTP | sem Dockerfile |
| apps/mobile | Expo | APIs HTTP | não é workload Kubernetes |

O Compose atual mantém cinco PostgreSQL separados, RabbitMQ, MongoDB e MailHog. A separação lógica de dados por serviço deve ser preservada. Em ambientes não produtivos de baixo custo, uma única instância PostgreSQL pode hospedar bancos e usuários separados; produção deve usar isolamento, backup e HA proporcionais ao risco.

## Gaps que impedem um deploy produtivo imediato

- Não há pipeline/registry e convenção de tags imutáveis para todas as imagens.
- `apps/web` não possui imagem OCI; `provider-service` não é reproduzível sem binário do host.
- Os scripts SQL são inicialização de Compose, não migrations idempotentes com histórico.
- Há segredos reais/defaults no Compose e no código; eles não devem ser copiados para GitOps.
- `logger-service` lê `MONGO_URL`, enquanto o Compose fornece `MONGO_URI`.
- Probes dedicadas não foram identificadas; o chart usa TCP até existirem endpoints de saúde.
- Ingress, TLS, CORS e URLs públicas por ambiente ainda precisam de contratos explícitos.
- Recursos, SLOs, backup/restore, retenção de logs e política de DR ainda não estão definidos.

## Topologia

### Agora: validação barata

Um cluster local com namespaces `wellpass-dev`, `wellpass-sit`, `wellpass-uat` e `wellpass-prod`. Argo CD observa este repositório; Kustomize instala dependências locais e o chart Helm instala os workloads. Use `prod` local apenas como validação de configuração, nunca como produção real.

### Depois: produção

- Conta AWS separada para produção e, preferencialmente, outra para não-produção.
- Um cluster compartilhado para dev/SIT/UAT pode ser aceitável; produção em cluster separado.
- ECR para imagens; EKS apenas quando a necessidade operacional justificar o custo fixo.
- RDS PostgreSQL (bancos/roles separados ou instâncias separadas por criticidade), Amazon MQ/RabbitMQ ou migração deliberada para SQS/SNS, e DocumentDB/MongoDB Atlas somente após teste de compatibilidade.
- External Secrets + AWS Secrets Manager, ALB/NLB ingress, ACM, Route 53, observabilidade e backups.

## Promoção

1. CI do monorepo testa e publica imagem com tag do commit e digest.
2. PR no infra altera somente os digests de `dev`.
3. Testes black-box promovem o mesmo digest para SIT, depois UAT.
4. Aprovação manual promove exatamente o mesmo digest para produção.

Não reconstruir a imagem entre ambientes. Configuração varia por valores; artefato não.

## LocalStack, MiniStack e Floci

Os três são emuladores de APIs AWS, não substitutos de Kubernetes. `MiniStack` e `Floci` são projetos válidos, mas recentes; sua compatibilidade deve ser comprovada serviço a serviço. Como o Wellpass atual não chama AWS SDKs, adotar um deles agora adicionaria uma camada sem testar comportamento relevante. Quando S3/SQS/SNS/Secrets Manager entrarem no produto, rode testes de contrato contra um emulador e mantenha uma verificação periódica em AWS real.

## Custos e limitações

| Opção | Ordem de custo | Uso recomendado | Limitação principal |
|---|---:|---|---|
| kind/k3d/minikube local | US$ 0 de nuvem | dev, CI e demonstração GitOps | depende da máquina; não valida IAM, rede e serviços gerenciados AWS |
| VPS única com k3s | ~US$ 20–80/mês | SIT/UAT temporários | sem HA; operação e backups por sua conta |
| EKS único compartilhado | a partir de US$ 73/mês só pelo control plane, mais nodes/storage/rede | pré-produção próxima de AWS | custo fixo e complexidade operacional |
| quatro clusters EKS | a partir de US$ 292/mês só de control planes | isolamento forte | desproporcional para esta fase |
| RDS/MQ/DocumentDB por ambiente | variável, rapidamente centenas/mês | produção/ensaios específicos | multiplicação do custo por ambiente |

Valores são ordem de grandeza, sem impostos e sujeitos a região/data. Use a calculadora AWS antes da decisão. Para economizar: ambientes não-prod desligáveis, um cluster não-prod, Spot onde tolerável e dependências in-cluster fora de produção.

## Critérios de saída

- `helm lint/template` e `kubectl kustomize` passam.
- Imagens reproduzíveis e assinadas estão no registry.
- Smoke/E2E passam em cada ambiente.
- Segredos não aparecem no Git nem nos valores renderizados.
- Backup e restore foram exercitados antes de produção.
- NetworkPolicies, requests/limits, PDB e probes HTTP estão definidos antes de produção real.

