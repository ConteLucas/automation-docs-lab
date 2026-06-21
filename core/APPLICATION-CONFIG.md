# Configuração Spring Boot — automation-core-lab

## Arquivo

Tudo em **`src/main/resources/application.yml`** (YAML, perfis com `---`):

| Perfil | Porta | `ddl-auto` | Massa SQL |
|--------|-------|------------|-----------|
| `local` (default) | 8081 | `update` | `always` |
| `docker` | 8081 | `validate` | `never` |
| `dev` | 8080 | `validate` | `never` |
| `prod` | 8080 | `validate` | `never` |

Override: `SPRING_PROFILES_ACTIVE`, `SPRING_JPA_HIBERNATE_DDL_AUTO`, `DB_*`, `APP_*`.

EC2 lab: compose prod default `SPRING_JPA_HIBERNATE_DDL_AUTO=update`.

## Storage S3 (flows / PNGs)

Ver [FLOW-SYNC-E-S3.md](../FLOW-SYNC-E-S3.md) e [env-images-s3.md](../infra/docs/env-images-s3.md).

| Variável | Default local | Prod |
|----------|---------------|------|
| `APP_STORAGE_MODE` | `local` | `s3` |
| `APP_STORAGE_S3_APP_ROOT` | `automation-device-lab` | idem |
| `APP_STORAGE_S3_DEPLOY_ENV` | `LOCAL` | `PROD` |
| `APP_STORAGE_S3_PREFIX` | `macros` | `macros` |
| `APP_STORAGE_S3_MANIFEST_PREFIX` | `json/bot` | `json/bot` |

`image_path` no BD é relativo; chave S3 = `{appRoot}/{deployEnv}/{prefix}/` + path.

Opcional: `application.yml` na **raiz do repo** sobrescreve o do JAR ao rodar `mvn spring-boot:run` local.

## Massa e seeds

`AUTOMATION_DB_LAB_ROOT` (default `../automation-db-lab`):

- `sql/core/massa.sql`
- `seeds/permission-seed.json`

## Swagger

Docker `:8082` → http://localhost:8082/swagger-ui/index.html · perfil `prod`: desligado.
