# Segurança em produção (automation-core-ddt)

## Profile `prod`

Ative com `SPRING_PROFILES_ACTIVE=prod`. O core **falha no startup** se:

| Variável | Requisito |
|----------|-----------|
| `APP_TOKEN_SECRET` | Definida e diferente de `change-me-local-secret` |
| `APP_GAME_ENCRYPTION_KEY` | Base64 de **32 bytes** (AES-256-GCM) |

Gere chaves:

```bash
openssl rand -base64 32   # APP_GAME_ENCRYPTION_KEY
openssl rand -base64 48   # APP_TOKEN_SECRET (sugestão)
```

Outras regras do profile:

- `spring.jpa.hibernate.ddl-auto: validate`
- Sem `massa.sql` / sample data
- `app.security.worker-require-device-key: true`
- Swagger UI desabilitado
- SQL DEBUG desligado

## Senhas `user_admin`

- BCrypt (substitui SHA-256 legado).
- Login com hash legado re-hash em BCrypt automaticamente.
- `device.api_key_hash` também usa BCrypt.

## Senhas `game_account`

- Criptografia reversível AES-256-GCM em repouso (`v1:` + base64).
- Worker e API admin (roles autorizados) recebem plaintext após decrypt no adapter.
- Migração automática na startup: linhas sem prefixo `v1:` são regravadas criptografadas (com chave definida).

**Backup do BD antes da primeira deploy com chave.**

### Rotação de chave

1. Backup BD.
2. Decrypt com chave antiga + re-encrypt com chave nova (script offline ou janela de manutenção).
3. Deploy com nova `APP_GAME_ENCRYPTION_KEY`.

## Worker `claim-next`

Em produção, **não** use Bearer de usuário CRM. Envie:

```http
POST /api/tasks/claim-next
Content-Type: application/json

{
  "deviceIdentifier": "device-android-001",
  "deviceApiKey": "<api-key-do-device>"
}
```

Planos worker (`GET /api/tasks/worker/**`) em prod:

```http
X-Device-Identifier: device-android-001
X-Device-Api-Key: <api-key>
```

Dev/docker: `APP_SECURITY_WORKER_REQUIRE_DEVICE_KEY=false` (api key opcional).

## CORS

`APP_ALLOWED_ORIGINS` — origem(s) do app-web, vírgula para múltiplas.

## Docker

Copie `.env.prod.example` → `.env.prod` e rode:

```bash
docker compose --env-file .env.prod up -d
```

Na EC2 o Terraform cria `/opt/automation-learn/.env.prod` — ver [automation-infra-lab](../../../automation-infra-lab/README.md).

## CRM

- Controllers CRM com `@RequirePermission` (function codes do `permission-seed.json`).
- Criação de pedido usa sempre o usuário autenticado (sem `userAdminId` no body).
