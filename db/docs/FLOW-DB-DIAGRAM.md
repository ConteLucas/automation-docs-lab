# Flow DB — visão geral (pós-V10)

Diagrama do banco depois da migration de referência [`sql/core/V10__flow_versioning_transition.sql`](../../../automation-db-lab/sql/core/V10__flow_versioning_transition.sql).
Contrato dos campos: [`FLOW-CONTRACT.md`](FLOW-CONTRACT.md).

**Legenda:** 🆕 nova coluna (V10) · ⚠️ legado (sai/renomeia) · 🔗 FK

---

## ER — hierarquia L1–L4

```mermaid
erDiagram
    collection ||--o{ flow : "1 → N"
    flow ||--o{ flow_step : "1 → N"
    flow_step ||--|| flow_step_image : "1 → 1"
    collection ||--o{ task : "task.collection_id"

    collection {
        bigint id PK
        varchar collection_key "chave negócio"
        varchar name_collection
        varchar default_flow_key "🆕 ponteiro flow default"
        int display_order
        varchar version "🆕 0.0.N"
        varchar content_hash "🆕 sha256"
        boolean is_original "⚠️ legado"
        timestamptz created_at
        timestamptz updated_at
    }

    flow {
        bigint id PK
        bigint collection_id FK "🔗 collection"
        varchar flow_key "UNIQUE(collection_id,flow_key)"
        varchar name
        int display_order
        varchar version "🆕 0.0.N"
        varchar content_hash "🆕 sha256"
        timestamptz created_at
        timestamptz updated_at
    }

    flow_step {
        bigint id PK
        bigint flow_id FK "🔗 flow"
        int step_number "UNIQUE(flow_id,step_number)"
        varchar name
        varchar step_key
        varchar version "🆕 0.0.N"
        varchar content_hash "🆕 sha256"
        varchar flow_key "⚠️ legado migração"
        varchar path_files "⚠️ legado (path deriva da L4)"
        timestamptz created_at
        timestamptz updated_at
    }

    flow_step_image {
        bigint id PK
        bigint flow_step_id FK "🔗 flow_step"
        int step_img_number "UNIQUE(flow_step_id,step_img_number)"
        varchar image_path "path S3 (binário no S3)"
        varchar name_image
        text coordinates
        varchar worker_action "CLICK|IF_VISIBLE|WAIT_APPEAR"
        varchar effect "FILL_LOGIN|GET_LEVEL..."
        varchar transition_flow_key "🆕 rota GOTO → flow L2"
        int transition_from_step_number "🆕 step de entrada"
        int timeskip_ms
        int width
        int height
        varchar version "🆕 0.0.N (versão visível)"
        varchar content_hash "🆕 sha256 do PNG"
        timestamptz created_at
        timestamptz updated_at
    }

    task {
        bigint id PK
        bigint collection_id FK "🔗 collection (wire: flowId ⚠️)"
        bigint game_account_id
        bigint device_id
        varchar status_task
        timestamptz created_at
        timestamptz updated_at
    }
```

---

## O que mudou no V10

| Tabela | 🆕 Adicionado | 🔴 Removido |
|--------|---------------|-------------|
| `collection` | `version`, `content_hash`, `default_flow_key` | — |
| `flow` | `version`, `content_hash` | — |
| `flow_step` | `version`, `content_hash` | — |
| `flow_step_image` | `version`, `content_hash`, `transition_flow_key`, `transition_from_step_number` | — |
| `flow_transition` | — | **tabela inteira** (rota virou coluna na L4) |

---

## Notas de modelagem

- **1:1 step ↔ imagem:** cada `flow_step` tem exatamente um `flow_step_image` (UNIQUE em `step_img_number`).
- **Versão = coluna, não tabela de revisão:** o DB guarda só a **versão atual**. O **histórico de binários vive no S3** (`0.0.1_x.png`, `0.0.2_x.png`). Revert = `UPDATE version` de volta + `DELETE` do PNG rejeitado no S3.
- **transition = dado, sem tabela própria:** a rota GOTO é interpretada pelo código do bot, mas persiste como coluna na imagem onde dispara.
- **`content_hash`:** complementa a versão visível — acelera o delta-sync e garante integridade no upload. `version` = rótulo humano; `content_hash` = fingerprint da máquina (sha256 do PNG / JSON canônico).
- **`updated_at` ↔ `current_*.json.updatedAt`:** toda linha tem `updated_at`; o ponteiro `current_*.json` espelha esse timestamp para saber **quando** virou a versão atual (forward ou revert).
- **Legados (⚠️):** `is_original`, `flow_step.flow_key`, `path_files`, e o alias `task.flowId`(=`collection_id`) seguem por compatibilidade; migrar depois.

*Reflete V10 + FLOW-CONTRACT — Jun 2026.*
