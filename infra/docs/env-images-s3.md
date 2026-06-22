# Imagens de flow e layout S3

Como o Core guarda PNGs, espelha manifests worker e particiona o bucket por **app** e **deploy env**.

> Visão transversal: [FLOW-SYNC-E-S3.md](../../FLOW-SYNC-E-S3.md)

**Última atualização:** 2026-06-20

---

## Resumo

| Ambiente | `APP_STORAGE_MODE` | `APP_STORAGE_S3_DEPLOY_ENV` | Onde ficam os PNGs |
|----------|-------------------|----------------------------|-------------------|
| Dev (Docker Mac) | `local` | `LOCAL` (se S3) | Volume `/data/uploads` ou S3 `…/LOCAL/macros/…` |
| AWS lab (EC2) | `s3` | `PROD` | `automation-device-lab/PROD/macros/…` |
| Homologação | `s3` | `HMG` | `automation-device-lab/HMG/macros/…` |

O **Postgres** guarda `flow_step_image.image_path` **relativo** (sem prefixo de app/env):

```text
collections/LOCAL/flows/LOGIN/steps/0/img/0.0.1_xx.png
```

Chave S3 completa (Core compõe na hora do upload/presign):

```text
automation-device-lab/PROD/macros/collections/LOCAL/flows/LOGIN/steps/0/img/0.0.1_xx.png
```

---

## Variáveis de ambiente

| Variável | Descrição | Local (compose) | Prod (`.env.prod` EC2) |
|----------|-----------|-----------------|------------------------|
| `APP_STORAGE_MODE` | `local` ou `s3` | `local` | `s3` |
| `APP_STORAGE_S3_BUCKET` | Bucket | — | `automation-learn-lab-images-…` |
| `APP_STORAGE_S3_REGION` | Região | — | `us-east-1` |
| `APP_STORAGE_S3_APP_ROOT` | Raiz da app no bucket | `automation-device-lab` | `automation-device-lab` |
| `APP_STORAGE_S3_DEPLOY_ENV` | Ambiente de deploy | `LOCAL` | `PROD` |
| `APP_STORAGE_S3_PREFIX` | Segmento macros | `macros` | `macros` |
| `APP_STORAGE_S3_MANIFEST_PREFIX` | Segmento JSON bot | `json/bot` | `json/bot` |
| `APP_STORAGE_PUBLIC_BASE_URL` | Redirect opcional GET /file | vazio | vazio* |

\* Bucket **privado** por padrão — leitura via IAM (EC2) ou presign (bot).

### Onde cada env é definida

```text
Local:   automation-configs-lab/docker-compose.yml
Prod:    Terraform user-data → /opt/automation-learn/.env.prod
         automation-infra-lab/compose/docker-compose.prod.yml
```

Perfis Spring (`application.yml`): `local`→LOCAL, `dev`→HMG, `prod`→PROD.

---

## Árvore S3

```text
s3://{BUCKET}/automation-device-lab/{LOCAL|HMG|PROD}/
  macros/collections/{collectionKey}/flows/{flowKey}/steps/{n}/img/{file}.png
  macros/marketlab/galeria/anuncio/{accountId}/img/{file}.jpg
  macros/marketlab/chat/…
  json/bot/collections/{collectionKey}/latest.json
  json/bot/collections/{collectionKey}/flows/{flowKey}/releases/{planVersion}/flow.json
```

Implementação: `S3StorageLayout`, `FlowImagePathUtil`, `ImageStorageKeyUtil` no Core.

---

## Fluxos que usam storage

### 1. Web — upload de template

```text
POST /api/flow-step-images/upload  (multipart)
  → Core grava S3: {appRoot}/{deployEnv}/macros/…
  → retorna { "imagePath": "collections/LOCAL/flows/…" }
  → Web persiste imagePath em flow_step_image
```

### 2. Web — preview

```text
GET /api/flow-step-images/{id}/file
  → Core lê storage (local ou S3)
```

### 3. Bot — sync + execução

Com `WORKER_FLOW_SYNC_VIA_CORE=true`:

```text
GET  /api/tasks/worker/flow-sync/collections/{key}/latest   ← Core lê BD
POST /api/tasks/worker/flow-sync/presign { keys: […] }        ← URLs assinadas
POST claim-next (leve)
```

PNG nunca vai em Base64 no claim em prod.

### 4. Espelho automático (Core)

Após bump de versão (`FlowVersioningService` → `FlowMacroS3MirrorService`):

```text
PUT automation-device-lab/{ENV}/json/bot/collections/{key}/latest.json
PUT …/flows/{flowKey}/releases/{planVersion}/flow.json
```

---

## Scripts

### Sync PNGs (metadata → S3)

```bash
cd automation-configs-lab/vision-lab/scripts
S3_DEPLOY_ENV=PROD ./sync-metadata-images-to-s3.sh
# bucket e região opcionais; defaults no script
```

Variáveis: `S3_APP_ROOT`, `S3_DEPLOY_ENV`, `S3_ROOT_PREFIX` (default `{APP_ROOT}/{ENV}/macros`).

### Export manual manifest (Core → S3)

```bash
cd automation-configs-lab/infra-lab/scripts
COLLECTION_ID=… S3_DEPLOY_ENV=PROD ./export-flow-manifest-s3.sh
```

Credenciais worker: `bot-lab/credentials/worker-credentials.env`.

### Reconcile manifests (BD → S3)

```bash
# Via API Core (requer JWT admin)
COLLECTION_ID=3 JWT=eyJ... ./infra-lab/scripts/republish-worker-mirror.sh
# ou POST /api/collections/{id}/republish-worker-mirror
```

### Migração paths legados

```bash
DRY_RUN=1 ./infra-lab/scripts/migrate-s3-legacy-prefix.sh
S3_DEPLOY_ENV=PROD ./infra-lab/scripts/migrate-s3-legacy-prefix.sh
```

### Promote catálogo local → PROD

```bash
COLLECTION_ID=3 JWT=... ./infra-lab/scripts/promote-catalog-to-prod.sh
```

### Deploy Core após mudança Java

```bash
./infra-lab/scripts/deploy-service.sh core 54.225.198.82 ~/.ssh/automation-learn-lab.pem
```

---

## IAM (EC2)

Policy permite `s3:*Object` em:

```text
automation-device-lab/PROD/*
```

(macros + json/bot no mesmo prefixo de ambiente).

---

## Troubleshooting

| Problema | Causa provável | Solução |
|----------|----------------|---------|
| Upload 500 em prod | Env S3 incompleta | Conferir `.env.prod`: `APP_ROOT`, `DEPLOY_ENV`, `PREFIX=macros` |
| Upload 500 galeria MarketLAB | IAM EC2 só permite `{appRoot}/{ENV}/macros/*` | Galeria em `macros/marketlab/galeria/…`; ver logs `s3:PutObject` 403 |
| Bot sem PNG | Objeto no path legado `img/flows/` | Re-sync com `S3_DEPLOY_ENV=PROD` |
| Manifest 404 | JSON no env errado | Core e scripts com mesmo `DEPLOY_ENV` |
| Confusão LOCAL | Collection key vs deploy env | Ver [FLOW-SYNC-E-S3.md](../../FLOW-SYNC-E-S3.md) |

---

## Paths legados (migrar)

| Antigo | Atual |
|--------|-------|
| `img/flows/…` | `automation-device-lab/{ENV}/macros/collections/…` |
| `macros/collections/…` (sem env) | `automation-device-lab/{ENV}/macros/collections/…` |
| `json/bot/…` (raiz bucket) | `automation-device-lab/{ENV}/json/bot/…` |

---

## Arquivos relevantes

```text
automation-core-lab/
  adapter/out/storage/  S3StorageLayout, FlowImagePathUtil, FlowMacroS3MirrorService
  application/service/  WorkerFlowSyncService, FlowVersioningService
automation-infra-lab/
  terraform/locals.tf   s3_app_root, s3_deploy_env
  compose/docker-compose.prod.yml
automation-configs-lab/
  vision-lab/scripts/sync-metadata-images-to-s3.sh
  infra-lab/scripts/export-flow-manifest-s3.sh
```

Ver também: [DEPLOY-DEV.md](./DEPLOY-DEV.md), [GITHUB-DEPLOY.md](./GITHUB-DEPLOY.md).
