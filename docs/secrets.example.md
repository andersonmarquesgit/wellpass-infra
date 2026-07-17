# Contrato dos Secrets por serviço

Crie `<service>-secrets` fora do Git, por namespace. Em ambientes compartilhados/reais, use External Secrets ou Sealed Secrets.

- `DSN` específico por serviço
- `SECRET_KEY`
- `MEMBERSHIP_INTERNAL_TOKEN`
- `INTERNAL_SERVICE_TOKEN`
- credenciais SMTP e do registry, quando aplicável

O script local cria valores descartáveis. Nunca os reutilize fora do cluster local.
