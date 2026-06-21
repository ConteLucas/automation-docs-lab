# Índice — Core API (`automation-core-lab`)

Backend Spring Boot — tasks, flows, storage, worker sync.

**Última atualização:** 2026-06-20

---

## Início rápido

| Documento | Conteúdo |
|-----------|----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Hexagonal, camadas, integrações |
| [APPLICATION-CONFIG.md](APPLICATION-CONFIG.md) | Perfis Spring, env vars, massa SQL |
| [FLUXO-TASK-HEXAGONAL.md](FLUXO-TASK-HEXAGONAL.md) | Fluxo task end-to-end |

---

## Flows, storage e worker sync

| Documento | Conteúdo |
|-----------|----------|
| [../FLOW-SYNC-E-S3.md](../FLOW-SYNC-E-S3.md) | **BD → S3 → Bot** — layout, envs, espelho |
| [../infra/docs/env-images-s3.md](../infra/docs/env-images-s3.md) | Variáveis `APP_STORAGE_S3_*`, scripts sync |
| [FLOW-TABLE-README.md](FLOW-TABLE-README.md) | Tabelas flow / step / image |
| [FLOW-IS-ORIGINAL.md](FLOW-IS-ORIGINAL.md) | Flag `is_original` (legado) |
| [FLOW-RELEVANCIA-E-ORIGINAL-PROPOSAL.md](FLOW-RELEVANCIA-E-ORIGINAL-PROPOSAL.md) | Proposta relevância |

Contrato BD ↔ JSON: [../automation-db-lab/docs/FLOW-CONTRACT.md](../automation-db-lab/docs/FLOW-CONTRACT.md)

---

## Tasks e worker

| Documento | Conteúdo |
|-----------|----------|
| [TASK-WORKER-CLAIM.md](TASK-WORKER-CLAIM.md) | `claim-next`, bypass de versão, plano leve |
| [TASK-GENERATION-ACCOUNTS.md](TASK-GENERATION-ACCOUNTS.md) | Geração de tasks a partir de pedidos |
| [ENDPOINT-APPROVAL-TASKS.md](ENDPOINT-APPROVAL-TASKS.md) | Aprovação de tasks |

---

## Segurança e produção

| Documento | Conteúdo |
|-----------|----------|
| [SECURITY-PRODUCTION.md](SECURITY-PRODUCTION.md) | JWT, device key, AES contas |
| [CORE-DATABASE-TABLES.md](../../automation-db-lab/docs/CORE-DATABASE-TABLES.md) | Modelo relacional (canónico) |

---

## Refatoração / histórico

| Documento | Conteúdo |
|-----------|----------|
| [HEXAGONAL-REFACTOR-PLAN.md](HEXAGONAL-REFACTOR-PLAN.md) | Plano hexagonal |
| [REPOSITORIES-OVERVIEW.md](REPOSITORIES-OVERVIEW.md) | Visão multi-repo (cópia) |

---

## Por objetivo

**Flows + S3** → [FLOW-SYNC-E-S3.md](../FLOW-SYNC-E-S3.md) → [env-images-s3.md](../infra/docs/env-images-s3.md)

**Core local** → [APPLICATION-CONFIG.md](APPLICATION-CONFIG.md) → [../infra/docs/DEPLOY-DEV.md](../infra/docs/DEPLOY-DEV.md)

**Claim do bot** → [TASK-WORKER-CLAIM.md](TASK-WORKER-CLAIM.md) → [../bot/guia-execucao-task-core.md](../bot/guia-execucao-task-core.md)
