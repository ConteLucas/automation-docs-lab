# Flow — contrato (JSON ↔ DB ↔ DTO wire)

Fonte da verdade de **campos**. Liga as 4 superfícies: metadata JSON (bot), tabela DB, DTO wire (Core), UI (web).
Plano: [`FLOW-PLAN.md`](FLOW-PLAN.md). Detalhe: [`FLOW-METADATA-ALIGNMENT.md`](FLOW-METADATA-ALIGNMENT.md).

> **Regra-mãe:** o JSON metadata espelha a tabela. O **BD** é fonte da verdade do grafo. O **S3** guarda PNG + espelho JSON worker em `automation-device-lab/{DEPLOY_ENV}/`. Ver [FLOW-SYNC-E-S3.md](../../automation-docs-lab/FLOW-SYNC-E-S3.md).

**Legenda de status:**

| | Significado |
|---|---|
| 🟢 **Acordado** | decidido + já existe no código |
| 🟡 **Pendente** | decidido no plano, **falta implementar** |
| 🔴 **Legado** | existe hoje, **vai sair / renomear** |

---

## 0. Hierarquia × tabela × DTO (mapa rápido)

| Nível | Metadata (pasta) | Tabela DB | Entity JPA | DTO wire (claim/plan) |
|-------|------------------|-----------|------------|-----------------------|
| L1 Collection | `collections/LOCAL/` | `collection` | `CollectionEntity` | `TaskWorkerPlanCollectionDto` |
| L2 Flow | `flows/LOGIN/` | `flow` | `FlowEntity` | `TaskWorkerPlanFlowL2Dto` |
| L3 Step | `steps/5/` | `flow_step` | `FlowStepEntity` | `TaskWorkerPlanStepDto` |
| L4 Img | `steps/5/img/` | `flow_step_image` | `FlowStepImageEntity` | `TaskWorkerPlanImageDto` |

**Serialização Core:** Jackson **camelCase**, sem `@JsonProperty` (nome do campo Java == chave JSON wire).

---

## L1 — Collection

| JSON metadata | Coluna DB (`collection`) | DTO wire | Status | Nota |
|---------------|--------------------------|----------|--------|------|
| `collectionKey` | `collection_key` VARCHAR(64) | `collectionKey` | 🟢 | chave de negócio |
| `name` | `name_collection` VARCHAR(128) | `name` | 🟢 | DTO normaliza `name_collection`→`name` |
| `defaultFlowKey` | — | — | 🟡 | só metadata; DB não tem (decidir coluna ou derivar) |
| `flowOrder[]` | `flow.display_order` | (ordem de `flows[]`) | 🟡 | ordem deriva de `display_order` por flow |
| `version` (`0.0.1`) | `version` (a criar) | `planVersion` | 🟡 | hoje `planVersion` = `max(updated_at)` ISO, **não** semver |
| — | `id` BIGSERIAL | `id` | 🟢 | PK |
| — | `is_original` BOOL | — | 🔴 | legado, não usado no plano |
| — | — | (`task.flowId`) | 🔴 | `task.flowId` == `collection.id` (alias legado) |

Ponteiro: `current_collection.json` → `{ "version": "0.0.1", "updatedAt": "<ISO>" }` (espelha `collection.updated_at`).

---

## L2 — Flow

| JSON metadata | Coluna DB (`flow`) | DTO wire | Status | Nota |
|---------------|--------------------|----------|--------|------|
| `flowKey` | `flow_key` VARCHAR(64) | `flowKey` | 🟢 | UNIQUE `(collection_id, flow_key)` |
| `name` | `name` VARCHAR(128) | `name` | 🟢 | |
| (ordem) | `display_order` INT | — | 🟢 | |
| `version` (`0.0.1`) | `version` (a criar) | `planVersion` | 🟡 | mesma pendência semver do L1 |
| — | `collection_id` FK | — | 🟢 | pai |
| — | `id` BIGSERIAL | `id` | 🟢 | chave do cache claim (`cachedPlanVersionsByFlowId`) |

Ponteiro: `current_flow.json` → `{ "version": "0.0.1", "updatedAt": "<ISO>" }` (espelha `flow.updated_at`). **Claim usa `flow.id` (string) como chave do mapa de versões.**

---

## L3 — Step

| JSON metadata | Coluna DB (`flow_step`) | DTO wire | Status | Nota |
|---------------|-------------------------|----------|--------|------|
| (pasta `steps/N/`) | `step_number` INT | `stepNumber` | 🟢 | UNIQUE `(flow_id, step_number)` |
| `name` | `name` VARCHAR(128) | `name` | 🟢 | |
| `version` (`0.0.1`) | `version` (a criar) | — | 🟡 | |
| — | `flow_id` FK | — | 🟢 | pai |
| — | `step_key` VARCHAR(64) | `stepKey` | 🟡 | usado hoje no path; rever necessidade |
| — | `path_files` VARCHAR(512) | `pathFiles` | 🔴 | substituído por path derivado L4 |
| — | `flow_key` VARCHAR(64) | — | 🔴 | legado de migração |

> **`workerAction` / `effect` / `transition` não são um "nível" de hierarquia** — são **instruções de comportamento** que o **código do bot interpreta** (enums definidos em código). Mas **persistem como dado** na entidade L4 (`flow_step_image`), porque cada imagem precisa saber a ação. `transition` é rota (instrução de código) e **mesmo assim vira coluna** — só **não tem tabela própria**.

Ponteiro: `current_step.json` → `{ "version": "0.0.1", "updatedAt": "<ISO>" }` (espelha `flow_step.updated_at`).

---

## L4 — Step Image (1 PNG por step)

| JSON metadata | Coluna DB (`flow_step_image`) | DTO wire (`...ImageDto`) | Status | Nota |
|---------------|-------------------------------|--------------------------|--------|------|
| `imgFile` / `file` | `image_path` VARCHAR(512) | `file` | 🟢 | DB guarda **path**; wire manda **só filename** |
| `current_img.file` | (filename do path) | — | 🟢 | ponteiro ativo |
| `workerAction` | `worker_action` VARCHAR(64) def `CLICK` | `workerAction` | 🟢 | `CLICK`,`IF_VISIBLE`,`WAIT_APPEAR` |
| `effect` | `effect` VARCHAR(64) | `effect` | 🟢 | `FILL_LOGIN`,`GET_LEVEL`… |
| `transition.flowKey` | `transition_flow_key` VARCHAR(64) (a criar) | `transition` | 🟡 | **coluna** na entidade (NÃO tabela `flow_transition` 🔴). Rota é instrução de código, mas persiste como dado |
| `transition.fromStepNumber` | `transition_from_step_number` INT (a criar) | `transition` | 🟡 | opcional |
| `timeskipMs` | `timeskip_ms` INT | `timeskipMs` | 🟢 | |
| — | `coordinates` TEXT | `coordinates` | 🟢 | |
| — | `width` / `height` INT | `width`/`height` | 🟢 | |
| `version` (`0.0.1`) | `version` VARCHAR (a criar) | — | 🟡 | versão visível humana |
| — | `content_hash` VARCHAR (a criar) | — | 🟡 | integridade / delta |
| — | `step_img_number` INT | `stepImgNumber` | 🟢 | UNIQUE `(flow_step_id, step_img_number)`; 1:1 com step |
| — | (bytes) → `template_image`/`templateImage` | `templateImage` | 🟢 | Base64; só em plano completo `templates=base64` |
| — | `name_image` VARCHAR(255) | `nameImage` | 🟢 | |

Ponteiro: `current_img.json` → `{ "version": "0.0.1", "file": "0.0.1_04.png", "updatedAt": "<ISO>" }` (espelha `flow_step_image.updated_at`).

---

## Claim — contrato wire (existe hoje)

**`POST /api/tasks/claim-next`**

Request (`TaskClaimRequest`):
```json
{
  "deviceIdentifier": "string",
  "deviceApiKey": "string",
  "cachedPlanVersionsByFlowId": { "<flow.id>": "<planVersion>" }
}
```

Response `200` (`TaskWorkerPlanResponse`) / `204` se fila vazia:
```json
{
  "schemaVersion": 2,
  "generatedAt": "<Instant>",
  "task": { "id": 0, "flowId": 0, "gameAccountLogin": "...", "...": "..." },
  "collection": {
    "id": 0, "collectionKey": "LOCAL", "name": "...",
    "planVersion": "<max updated_at | futuro: 0.0.1>",
    "flows": [ { "id": 0, "flowKey": "LOGIN", "name": "...", "planVersion": "...", "steps": null } ],
    "transitions": null
  }
}
```

- 🟢 **Claim = plano leve:** índice de flows com `planVersion`; `steps`/`transitions`/`templateImage` **sempre null**.
- 🟢 Plano pesado: `GET /api/tasks/worker/collection-plan/{collectionId}?templates=manifest|base64`.
- 🟡 **Delta real por step/img** (versão `0.0.N`) ainda não existe — hoje o delta é por flow via `updated_at`.

---

## S3 — espelho do binário

| | Valor |
|---|---|
| 🟢 **Atual** | `automation-device-lab/{DEPLOY_ENV}/macros/collections/{collectionKey}/flows/{flowKey}/steps/{n}/img/{file}` |
| 🔴 Legado | `img/flows/…`, `flows/{collectionKey}/…` sem env |

BD (`flow_step_image.image_path`) guarda path **relativo** (`collections/LOCAL/flows/…`). Core compõe chave S3 completa no upload/presign.

Ver [FLOW-SYNC-E-S3.md](../../automation-docs-lab/FLOW-SYNC-E-S3.md).

---

## Versionamento

- 🟡 Patch automático `0.0.1` → `0.0.2` (máquina incrementa; **sem bump manual**). Bump = novo INSERT/revisão na tabela.
- 🟡 `content_hash` complementar (integridade + acelera delta).
- 🔴 Hoje: `planVersion` = `max(updated_at)` ISO-8601 agregado (não semver, não por-imagem).
- **Regra de propagação:** imagem muda → versão do **flow** muda → versão da **collection** muda. As **outras imagens não mudam**.

**`version` vs `content_hash`:**

| Campo | Para quem | Papel |
|-------|-----------|-------|
| `version` (`0.0.2`) | humano | rótulo legível — "qual é a atual" |
| `content_hash` (sha256) | máquina | fingerprint do conteúdo (PNG bytes / JSON canônico) — integridade, delta real, dedup, auditoria |

**`updatedAt` nos ponteiros `current_*.json`:** cada `current_*.json` carrega `updatedAt` (ISO) = instante em que o ponteiro passou a apontar pra essa versão (forward **ou** revert). Espelha `updated_at` da linha no DB — mesmo evento nos dois lados.

---

## Revert (UPDATE + apaga lixo)

Revert **não** é versão nova; é UPDATE do ponteiro + DELETE da rejeitada. **File (S3) e DB alinhados no mesmo passo.**

```text
1. current_img: 0.0.2 → 0.0.1   (UPDATE, sobrepõe)
2. S3:  DELETE 0.0.2_x.png        (lixo)
3. DB:  remove revisão 0.0.2
4. Bot: cache 0.0.2 ≠ current 0.0.1 → re-baixa 0.0.1
```

| Caso | Versão anterior |
|------|-----------------|
| Superada forward | **fica** (revertível) |
| Revertida (rejeitada) | **apaga** S3 **e** DB |

Sem "redo". Log: `imgKey xpto: 0.0.2 → 0.0.1 (revert)`.

---

## Decisões — travadas e em aberto

**Travadas (Jun 2026):**

1. ✅ **`workerAction`/`effect`/`transition` = instruções de código, persistem como dado na L4** (`flow_step_image`). Não são nível de hierarquia.
2. ✅ **`version` + `content_hash` nas 4 tabelas** (`collection`, `flow`, `flow_step`, `flow_step_image`). Sem bump manual; versão = nova revisão/INSERT.
3. ✅ **`transition` = coluna** (`transition_flow_key` + `transition_from_step_number`) na entidade. **Tabela `flow_transition` morre** 🔴.
4. ✅ **Grafo de transições da web = DERIVADO** das colunas `flow_step_image.transition_*` (query/VIEW), não de tabela própria. `transitions` sai do runtime do claim.
5. ✅ **`planVersion` → semver `0.0.N`** (coluna `version` no DB, bump no write), substituindo o `max(updated_at)` ISO atual. Comparação no claim continua string==string.

**Em aberto (default proposto entre parênteses):**

6. **`defaultFlowKey` / `flowOrder`**: coluna `default_flow_key` em `collection` + ordem via `flow.display_order` *(proposto)*.
7. **Naming legado no wire:** `task.flowId` (= collection.id), `flow_step.flow_key`, `path_files`, `step_key` — *manter alias por agora; migrar depois*.
8. **S3 path**: layout atual `automation-device-lab/{DEPLOY_ENV}/macros/collections/…` — ver [FLOW-SYNC-E-S3.md](../../automation-docs-lab/FLOW-SYNC-E-S3.md).

---

*Base: metadata POC LOCAL + DTOs/Entities do automation-core-lab + sql/core do automation-db-lab — Jun 2026.*
