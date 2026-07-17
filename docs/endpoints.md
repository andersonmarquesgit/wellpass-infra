# Endpoints

Após `make local-up`, publicação das imagens e sincronização do Argo CD:

| Ambiente | Web | Auth | Customer | Provider | Sessions | Notifications |
|---|---|---|---|---|---|---|
| dev | http://app.dev.127.0.0.1.nip.io | http://auth.dev.127.0.0.1.nip.io | http://customer.dev.127.0.0.1.nip.io | http://provider.dev.127.0.0.1.nip.io | http://sessions.dev.127.0.0.1.nip.io | http://notifications.dev.127.0.0.1.nip.io |
| sit | http://app.sit.127.0.0.1.nip.io | http://auth.sit.127.0.0.1.nip.io | http://customer.sit.127.0.0.1.nip.io | http://provider.sit.127.0.0.1.nip.io | http://sessions.sit.127.0.0.1.nip.io | http://notifications.sit.127.0.0.1.nip.io |
| uat | http://app.uat.127.0.0.1.nip.io | http://auth.uat.127.0.0.1.nip.io | http://customer.uat.127.0.0.1.nip.io | http://provider.uat.127.0.0.1.nip.io | http://sessions.uat.127.0.0.1.nip.io | http://notifications.uat.127.0.0.1.nip.io |
| prod (placeholder) | https://app.wellpass.example.com | https://auth.wellpass.example.com | https://customer.wellpass.example.com | https://provider.wellpass.example.com | https://sessions.wellpass.example.com | https://notifications.wellpass.example.com |

Argo CD é compartilhado. Use `kubectl -n argocd port-forward svc/argocd-server 8080:443` e acesse:

- https://localhost:8080/applications/argocd/wellpass-dev
- https://localhost:8080/applications/argocd/wellpass-sit
- https://localhost:8080/applications/argocd/wellpass-uat
- https://localhost:8080/applications/argocd/wellpass-prod

Dentro de cada namespace, os serviços internos seguem `<service>.wellpass-<env>.svc.cluster.local`.
