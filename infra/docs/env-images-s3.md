# Imagens de flow: storage local vs S3

Como o Core guarda e serve templates (`flow_step_image`) no **local** e na **AWS lab**.

## Resumo

| Ambiente | `APP_STORAGE_MODE` | Onde ficam os PNGs |
|----------|-------------------|-------------------|
| Dev (Docker Mac) | `local` | `automation-configs-lab/utils/data/ddt-templates/` → volume `/data/uploads` |
| AWS lab (EC2) | `s3` | Bucket S3 `automation-learn-lab-images-396913713116` |

O **mesmo código** do Core funciona nos dois modos. O Postgres sempre guarda `image_path` relativo (ex.: `flows/prod/login/login_01/01.png`).

## Variáveis de ambiente

Definidas no Core (`application.yml` → env `APP_STORAGE_*`):

| Variável | Local | Prod (`.env.prod` na EC2) |
|----------|-------|---------------------------|
| `APP_STORAGE_MODE` | `local` | `s3` |
| `APP_STORAGE_UPLOAD_DIR` | `/data/uploads` | `/data/uploads` (fallback, pouco usado em S3) |
| `APP_STORAGE_S3_BUCKET` | — | `automation-learn-lab-images-396913713116` |
| `APP_STORAGE_S3_REGION` | — | `us-east-1` |
| `APP_STORAGE_S3_PREFIX` | `img/flows` | `img/flows` |
| `APP_STORAGE_PUBLIC_BASE_URL` | vazio | vazio* |

\* Opcional. Se `s3_public_read_images = true` no Terraform, o Core pode redirecionar `GET /file` para URL pública S3 (menos tráfego na EC2). **Padrão do lab: bucket privado** — leitura via IAM da instância.

### Onde cada env é definida

```text
Local:   automation-configs-lab/docker-compose.yml
Prod:    Terraform user-data → /opt/automation-learn/.env.prod
         automation-infra-lab/compose/docker-compose.prod.yml (repassa ao container core)
```

## Chave no S3

`image_path` no banco + prefixo:

```text
image_path:  flows/prod/login/login_01/01.png
S3 key:      img/flows/flows/prod/login/login_01/01.png
```

Se `image_path` já começa com `img/flows/`, o prefixo **não** é duplicado.

Implementação: `ImageStorageKeyUtil` no `automation-core-lab`.

## Fluxos que usam storage

### 1. Web — upload de template

```text
POST /api/flow-step-images/upload  (multipart)
  → Core grava no storage (disco ou S3)
  → retorna { "imagePath": "flows/..." }
  → Web salva imagePath no registro flow_step_image
```

### 2. Web — preview da imagem

```text
GET /api/flow-step-images/{id}/file
  → Core lê do storage e devolve bytes
  → (opcional) redirect 302 se APP_STORAGE_PUBLIC_BASE_URL configurado
```

### 3. Bot — plano da task

| Query | Comportamento |
|-------|---------------|
| `?templates=manifest` (padrão) | JSON com `id` da imagem; bot baixa `GET /flow-step-images/{id}/file` |
| `?templates=base64` | Core lê do storage e embute `templateImage` em Base64 |

Em prod (S3), ambos leem do bucket via SDK (credenciais IAM da EC2).

## Local — setup de templates

```bash
# Copia PNGs do bot → pasta montada no Core
cd automation-configs-lab
./utils/scripts/sync-ddt-templates-to-storage.sh
```

Fonte: `automation-bot-lab/app/src/main/assets/worker-flows/flows/`  
Destino: `automation-configs-lab/utils/data/ddt-templates/flows/`

## Prod — setup inicial de templates

### 1. Deploy do Core com código S3

```bash
cd automation-configs-lab
./infra-lab/scripts/deploy-service.sh core 54.225.198.82 ~/.ssh/automation-learn-lab.pem
```

O script compila o JAR **no Mac** (`mvn package`) e na EC2 só empacota a imagem JRE (~30 s).

### 2. Sincronizar PNGs para o bucket (uma vez ou quando atualizar catálogo)

```bash
./vision-lab/scripts/sync-ddt-templates-to-s3.sh
# ou com bucket/região explícitos:
./vision-lab/scripts/sync-ddt-templates-to-s3.sh automation-learn-lab-images-396913713116 us-east-1 img/flows
```

Requer `aws` CLI autenticado (perfil local com permissão no bucket, ou rodar na EC2).

### 3. Banco

Os registros `flow_step_image.image_path` devem bater com o caminho relativo (ex.: `flows/prod/login/01.png`), igual ao local. Scripts de seed (`seed-ddt-login-flow.sh`, etc.) já geram esses paths.

## Custo (free tier)

Configuração pensada para **uso baixo, sem custo relevante**:

| Recurso | Free tier (12 meses) | Uso típico do lab |
|---------|----------------------|-------------------|
| S3 storage | 5 GB | Centenas de PNGs pequenos (<< 1 GB) |
| S3 GET | 20.000/mês | Bot cacheia localmente após 1º download |
| S3 PUT | 2.000/mês | Uploads ocasionais pelo web |
| EC2 → S3 (mesma região) | Sem cobrança de transferência | Core e bucket em `us-east-1` |

Boas práticas já aplicadas:

- Bucket **privado** (sem CloudFront obrigatório)
- Sem multipart para arquivos pequenos
- Bot usa modo `manifest` (não manda Base64 gigante em todo claim)
- Lifecycle no Terraform pode expirar versões antigas (se versioning ativo)

## IAM

A EC2 usa instance profile com policy `s3:PutObject`, `GetObject`, `DeleteObject` no prefixo `img/flows/*`. O Core usa `DefaultCredentialsProvider` (sem chave no `.env`).

## Troubleshooting

| Problema | Causa provável | Solução |
|----------|----------------|---------|
| Upload web 500 em prod | Core antigo ou bucket/region vazios | Redeploy `core`; conferir `.env.prod` |
| `GET /file` 404 | PNG não está no S3 | Rodar `sync-ddt-templates-to-s3.sh` |
| Bot sem template | `image_path` no banco ≠ objeto no S3 | Alinhar path do seed com sync |
| `app.storage.s3.bucket é obrigatório` | `APP_STORAGE_MODE=s3` sem bucket | Corrigir `.env.prod` / Terraform |
| Local OK, prod falha | Modo errado | `APP_STORAGE_MODE=s3` na EC2, `local` no Mac |

## Arquivos relevantes

```text
automation-core-lab/
  src/main/java/.../adapter/out/storage/
    LocalImageStorageAdapter.java
    S3ImageStorageAdapter.java
    ImageStorageKeyUtil.java
  src/main/java/.../application/config/
    StorageProperties.java
    ImageStorageConfiguration.java

automation-infra-lab/
  compose/docker-compose.prod.yml
  terraform/ (bucket, IAM, .env.prod)
  docs/env-images-s3.md          ← este arquivo

automation-configs-lab/
  docker-compose.yml             (mode=local)
  vision-lab/scripts/sync-ddt-templates-to-s3.sh
  vision-lab/scripts/sync-ddt-templates-to-storage.sh
```

## Deploy após mudança no storage

```bash
# Só o Core precisa rebuild quando alterar código Java de storage
../automation-configs-lab/infra-lab/scripts/deploy-service.sh core 54.225.198.82 ~/.ssh/automation-learn-lab.pem
```

Ver também: [DEPLOY-DEV.md](./DEPLOY-DEV.md), [GITHUB-DEPLOY.md](./GITHUB-DEPLOY.md).
