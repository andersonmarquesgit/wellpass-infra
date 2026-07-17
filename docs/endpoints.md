# Endpoints

Após `make local-up`, publicação das imagens e sincronização do Argo CD:

| Ambiente | Web | Auth | Customer | Provider | Sessions | Notifications |
|---|---|---|---|---|---|---|
| dev | http://app.dev.127.0.0.1.nip.io | http://auth.dev.127.0.0.1.nip.io | http://customer.dev.127.0.0.1.nip.io | http://provider.dev.127.0.0.1.nip.io | http://sessions.dev.127.0.0.1.nip.io | http://notifications.dev.127.0.0.1.nip.io |
| sit | http://app.sit.127.0.0.1.nip.io | http://auth.sit.127.0.0.1.nip.io | http://customer.sit.127.0.0.1.nip.io | http://provider.sit.127.0.0.1.nip.io | http://sessions.sit.127.0.0.1.nip.io | http://notifications.sit.127.0.0.1.nip.io |
| uat | http://app.uat.127.0.0.1.nip.io | http://auth.uat.127.0.0.1.nip.io | http://customer.uat.127.0.0.1.nip.io | http://provider.uat.127.0.0.1.nip.io | http://sessions.uat.127.0.0.1.nip.io | http://notifications.uat.127.0.0.1.nip.io |
| prod | http://app.prod.127.0.0.1.nip.io | http://auth.prod.127.0.0.1.nip.io | http://customer.prod.127.0.0.1.nip.io | http://provider.prod.127.0.0.1.nip.io | http://sessions.prod.127.0.0.1.nip.io | http://notifications.prod.127.0.0.1.nip.io |

Argo CD é compartilhado e exposto pelo ingress local, sem depender de um
`port-forward` temporário. Acesse via HTTP:

- http://argocd.127.0.0.1.nip.io/applications/argocd/wellpass-dev
- http://argocd.127.0.0.1.nip.io/applications/argocd/wellpass-sit
- http://argocd.127.0.0.1.nip.io/applications/argocd/wellpass-uat
- http://argocd.127.0.0.1.nip.io/applications/argocd/wellpass-prod

Dentro de cada namespace, os serviços internos seguem `<service>.wellpass-<env>.svc.cluster.local`.
