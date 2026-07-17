# Estratégia de secrets

## Local

`scripts/local-up.sh` gera secrets descartáveis por serviço. Eles nunca são gravados no Git.

## Ambientes compartilhados e produção

O contrato definitivo é External Secrets Operator + AWS Secrets Manager:

- um caminho por ambiente e serviço: `wellpass/<env>/<service>`;
- autenticação por IRSA/Pod Identity, sem access key estática;
- `ExternalSecret` materializa `<service>-secrets` no namespace;
- rotação no provedor e intervalo de refresh configurável;
- Argo CD gerencia somente referências, nunca valores.

As chaves mínimas são `DSN`, `SECRET_KEY`, `MEMBERSHIP_INTERNAL_TOKEN` e `INTERNAL_SERVICE_TOKEN`, conforme aplicável. Para o cluster local, o script de bootstrap implementa o mesmo nome de Secret para manter paridade.

Antes de produção, instale o External Secrets Operator e crie um `ClusterSecretStore` por conta AWS. Essa instalação é deliberadamente externa ao chart da aplicação para evitar que uma aplicação tenha autoridade para configurar o backend global de secrets.
