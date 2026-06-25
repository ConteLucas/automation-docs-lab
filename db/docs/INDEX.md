# Índice — Banco e flows

Documentação em `automation-docs-lab/db/docs`. SQL e seeds em `automation-db-lab`.

**Última atualização:** 2026-06-20

---

## Flows — fonte da verdade

| Documento | Conteúdo |
|-----------|----------|
| [FLOW-PLAN.md](FLOW-PLAN.md) | Plano hierarquia L1–L4, semver |
| [FLOW-CONTRACT.md](FLOW-CONTRACT.md) | Contrato JSON ↔ BD ↔ DTO |
| [FLOW-METADATA-ALIGNMENT.md](FLOW-METADATA-ALIGNMENT.md) | Metadata bot × Core |
| [FLOW-DB-DIAGRAM.md](FLOW-DB-DIAGRAM.md) | Diagrama ER |

Espelho S3: [../../automation-docs-lab/FLOW-SYNC-E-S3.md](../../automation-docs-lab/FLOW-SYNC-E-S3.md)

---

## Modelo e DDL

| Documento | Conteúdo |
|-----------|----------|
| [CORE-DATABASE-TABLES.md](CORE-DATABASE-TABLES.md) | Tabelas, convenções |
| [CORE-DATABASE-DDL.sql](CORE-DATABASE-DDL.sql) | DDL referência |
| [modeling/automation-ddt.drawio](modeling/automation-ddt.drawio) | Draw.io ER (5 páginas; gerar na raiz: `./generate-ddt-drawio.sh`) |

---

## SQL e seeds

| Pasta | Conteúdo |
|-------|----------|
| [sql/core/](../../../automation-db-lab/sql/core/) | massa.sql, alter-*.sql |
| [seeds/permission-seed.json](../../../automation-db-lab/seeds/permission-seed.json) | RBAC |

[README](../../../automation-db-lab/README.md) — como o Core consome este repo.

---

## Paths BD vs S3

| Onde | Exemplo |
|------|---------|
| `image_path` (BD) | `collections/LOCAL/flows/LOGIN/steps/0/img/0.0.1_xx.png` |
| Chave S3 | `automation-device-lab/PROD/macros/collections/LOCAL/…` |

Collection key **LOCAL** ≠ deploy env **LOCAL** — ver FLOW-SYNC-E-S3.md.
