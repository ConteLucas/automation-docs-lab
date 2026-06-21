# Índice — Infra AWS (`automation-infra-lab`)

Terraform, EC2, Docker Compose prod, S3, deploy.

**Última atualização:** 2026-06-21

---

## Releases e produto

| Documento | Conteúdo |
|-----------|----------|
| [../releases/INDEX.md](../releases/INDEX.md) | Histórico R00–R04 |
| [../releases/r04-producao-identidade/README.md](../releases/r04-producao-identidade/README.md) | Domínio, HTTPS, OAuth (última release) |

---

## Arquitetura

| Documento | Conteúdo |
|-----------|----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Topologia AWS, Terraform, compose |
| [../FLOW-SYNC-E-S3.md](../FLOW-SYNC-E-S3.md) | Layout S3 por deploy env |

---

## Deploy e operação

| Documento | Conteúdo |
|-----------|----------|
| [docs/DEPLOY-DEV.md](docs/DEPLOY-DEV.md) | Deploy por serviço |
| [docs/GITHUB-DEPLOY.md](docs/GITHUB-DEPLOY.md) | CI/CD |
| [docs/RESTART-INSTANCE.md](docs/RESTART-INSTANCE.md) | Reiniciar EC2 |
| [docs/AWS-VALIDATE.md](docs/AWS-VALIDATE.md) | Validar AWS |
| [docs/DOMAIN-SETUP.md](docs/DOMAIN-SETUP.md) | Domínio + HTTPS |

---

## Storage e banco

| Documento | Conteúdo |
|-----------|----------|
| [docs/env-images-s3.md](docs/env-images-s3.md) | S3 macros + json/bot |
| [../CHAT-S3.md](../CHAT-S3.md) | Chat unificado (transcripts .txt no S3) |
| [docs/DATABASE-REVIEW.md](docs/DATABASE-REVIEW.md) | Postgres EC2, DBeaver |
| [docs/apk-bot-s3.md](docs/apk-bot-s3.md) | APK no bucket |

---

## Comandos rápidos

```bash
cd automation-configs-lab/infra-lab
./scripts/deploy-service.sh core 54.225.198.82 ~/.ssh/automation-learn-lab.pem

cd ../vision-lab/scripts
S3_DEPLOY_ENV=PROD ./sync-metadata-images-to-s3.sh

# Reconcile manifests BD → S3
COLLECTION_ID=3 JWT=eyJ... ./republish-worker-mirror.sh

# Migração prefixos legados
DRY_RUN=1 ./migrate-s3-legacy-prefix.sh

# Promote completo (PNG + republish)
COLLECTION_ID=3 JWT=... ./promote-catalog-to-prod.sh
```
