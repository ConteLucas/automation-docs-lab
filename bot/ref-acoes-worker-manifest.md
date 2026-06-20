# `worker_action` no plano do worker: CLICK, WAIT_APPEAR, IF_VISIBLE

Referência de **onde o valor é definido** e **como o bot Android o interpreta** ao executar o plano vindo do Core (`claim-next` → `TaskWorkerPlan`).

**Relacionado:** [guia-orquestrador-task-core.md](guia-orquestrador-task-core.md), Core `FlowStepWorkerActionWire`, bot `ExecuteWorkerPlanUseCase`.

---

## 1. Onde o valor é definido

| Camada | O quê |
|--------|--------|
| **Base de dados (Core)** | Coluna `worker_action` em `flow_step_image` (por template / imagem do passo). |
| **Core (validação)** | `FlowStepWorkerActionWire` — literais permitidos: `CLICK`, `WAIT_APPEAR`, `IF_VISIBLE`; normalização para maiúsculas; default `CLICK` quando ausente em alguns fluxos. |
| **API / plano** | Cada imagem no plano do worker inclui `workerAction` (JSON). |
| **Web (`automation-app-web`)** | Formulários de `flow_step_image` permitem escolher `worker_action` por imagem. |
| **Bot** | `CoreTaskPlanMapper` mapeia o DTO → `WorkerStepImage.workerAction` (`trim`, `uppercase`, fallback `"CLICK"` se vazio). |

O **comportamento em tempo de execução** (o que fazer com screenshot, Vision e clique) está implementado no bot em:

`automation-bot-ddt/app/src/main/java/com/automation/bot/domain/usecases/worker/ExecuteWorkerPlanUseCase.kt`

Modelo: `WorkerStepImage` em `TaskWorkerPlan.kt` (`workerAction: String`).

---

## 2. Semântica no bot (resumo)

O use case percorre **steps ordenados por `stepNumber`** e, em cada step, **imagens ordenadas por `stepImgNumber`**. Para cada imagem:

1. Decodifica o template Base64.
2. Lê `action = img.workerAction.trim().uppercase()`.
3. Desvia conforme a tabela abaixo.

Todos os ramos que detetam template usam o mesmo **`lensThreshold`** injetado no use case e `visionRepository.detectElement(template, screenshot, lensThreshold)`. O clique, quando ocorre, é no **centro** do `ScreenMatch` (`clickRepository.clickAt`).

| Valor (`worker_action`) | Comportamento no bot |
|-------------------------|----------------------|
| **CLICK** | Um screenshot → deteção. **Sem match → falha** do plano (exceção). **Com match → clica.** Qualquer string diferente de `WAIT_APPEAR` e `IF_VISIBLE` cai neste ramo (`else`). |
| **WAIT_APPEAR** | **Não clica.** Faz até **90** tentativas com intervalo de **1 s** entre tentativas: screenshot → deteção. Quando há match, aguarda **300 ms** e segue. Se esgotar tentativas → **falha** (timeout). |
| **IF_VISIBLE** | Um screenshot → deteção. **Sem match → não falha:** log, **200 ms** de espera e passa para a **próxima imagem** (`continue`). **Com match → clica** (igual ao CLICK). |

---

## 3. Constantes de tempo (WAIT_APPEAR)

Definidas no `companion object` de `ExecuteWorkerPlanUseCase`:

- `WAIT_APPEAR_POLL_MS` = `1000` (1 segundo entre tentativas).
- `WAIT_APPEAR_MAX_ATTEMPTS` = `90` (no máximo ~90 segundos de espera antes de erro).

---

## 4. Contrato com o Core

Os três valores são os únicos aceites pelo Core na validação de criação/atualização de `flow_step_image` (ver `FlowStepWorkerActionWire.java`). O bot só precisa reconhecer essas strings (case-insensitive após `uppercase()` no mapper e no `when`).

---

## 5. Boas práticas de modelação

- **CLICK:** passo obrigatório na UI (botão, campo) que tem de estar visível para o fluxo avançar.
- **WAIT_APPEAR:** sincronização (splash, carregamento, animação) — esperar aparecer **sem** interagir.
- **IF_VISIBLE:** elementos opcionais (banner, “Concordo”, tutorial) — se não existirem, o fluxo continua.

Para alterar tempos ou política de retry de `WAIT_APPEAR`, o ponto único no bot é `ExecuteWorkerPlanUseCase`.
