# Documentação — automation-learn

Documentação centralizada por serviço em **`automation-docs-lab`**. Não commitar `docs/` nos repos de aplicação (`automation-core-lab`, `automation-bot-lab`, etc.).

**Última atualização:** 2026-06-20

---

## Comece aqui

| Documento | Conteúdo |
|-----------|----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Visão macro do ecossistema (diagramas, repos, segurança) |
| [FLOW-SYNC-E-S3.md](FLOW-SYNC-E-S3.md) | **Fluxo novo:** BD → Core → S3 → Bot (layouts, envs LOCAL/HMG/PROD) |
| [TECH-STORIES.md](TECH-STORIES.md) | Histórias técnicas e stack |
| [REPOSITORIES-OVERVIEW.md](REPOSITORIES-OVERVIEW.md) | Visão multi-repo |

---

## Índices por sistema

| Sistema | Índice | Repo de código |
|---------|--------|----------------|
| Core API (Spring) | [core/INDEX.md](core/INDEX.md) | `automation-core-lab` |
| Bot worker (Android) | [bot/INDEX.md](bot/INDEX.md) | `automation-bot-lab` |
| Vision / OCR | [vision/INDEX.md](vision/INDEX.md) | `automation-vision-lab` |
| Web UI (React) | [web/INDEX.md](web/INDEX.md) | `automation-web-lab` |
| Infra / deploy AWS | [infra/INDEX.md](infra/INDEX.md) | `automation-infra-lab` |
| Device Lab desktop | [device/INDEX.md](device/INDEX.md) | `automation-device-lab` |
| Banco / flows / seeds | [../automation-db-lab/docs/INDEX.md](../automation-db-lab/docs/INDEX.md) | `automation-db-lab` |

Scripts operacionais (compose, deploy, sync S3): **`automation-configs-lab`** — ver [infra/docs/DEPLOY-DEV.md](infra/docs/DEPLOY-DEV.md).

---

## Legado

Documentos históricos ou substituídos: [LEGACY.md](LEGACY.md).
