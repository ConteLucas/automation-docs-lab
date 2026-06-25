# Documentação — automation-learn

Documentação centralizada por serviço em **`automation-docs-lab`**. Não commitar `docs/` nos repos de aplicação (`automation-core-lab`, `automation-bot-lab`, etc.).

**Última atualização:** 2026-06-21

---

## Comece aqui

| Documento | Conteúdo |
|-----------|----------|
| [releases/INDEX.md](releases/INDEX.md) | **Histórico por release** (R00–R04) — evolução do sistema |
| [product/VISION.md](product/VISION.md) | Visão do produto (MacroLAB + MarketLAB) |
| [product/PROPOSAL.md](product/PROPOSAL.md) | Proposta e escopo por módulo |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Visão macro do ecossistema (diagramas, repos, segurança) |
| [db/ARCHITECTURE.md](db/ARCHITECTURE.md) | Modelo relacional e diagramas ER (atualizado por release) |
| [FLOW-SYNC-E-S3.md](FLOW-SYNC-E-S3.md) | BD → Core → S3 → Bot (layouts, envs LOCAL/HMG/PROD) |
| [TECH-STORIES.md](TECH-STORIES.md) | Histórias técnicas e stack (legado detalhado) |
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
| Banco / flows / seeds | [db/docs/INDEX.md](db/docs/INDEX.md) | docs em `automation-docs-lab`; SQL/seeds em `automation-db-lab` |

Scripts operacionais (compose, deploy, sync S3): **`automation-configs-lab`** — ver [infra/docs/DEPLOY-DEV.md](infra/docs/DEPLOY-DEV.md).

---

## Legado

Documentos históricos ou substituídos: [LEGACY.md](LEGACY.md).
