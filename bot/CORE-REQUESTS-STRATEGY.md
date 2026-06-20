# Estratégia: Core, Requests e comunicação Bot ↔ Vision ↔ Core

Documento de referência para o desenho de pedidos (requests), tabelas no Core, log de erros com screenshot e ordem de implementação.

---

## 1. Modelo unificado: SERVER (range / servidor único / ALL)

Um único campo **SERVER** representa o escopo do pedido/detalhe:

| Valor SERVER | Significado |
|--------------|-------------|
| `ALL` | Todas as posições/servidores; gera N linhas em REQUEST_DETAIL conforme CONFIG |
| `range_1` | Posições 1 a 9 |
| `range_2` | Posições 10 a 17 |
| `range_3` | Posições 18 a 28 e 56 a 60 |
| `range_4` | Posições 29 a 46 |
| `range_5` | Posições 47 a 55 |
| `range_6` | Restante (conforme definição de negócio) |
| `S1` … `S65` (e além) | Servidor único |

- **SERVER = ALL** só existe no **REQUEST**. Os detalhes ficam na **REQUEST_DETAIL**: são geradas N linhas (ex.: 65), cada uma com SERVER de 1 a `CONFIG.SERVER_ALL` (tabela CONFIG define o valor de ALL, ex.: 65).
- Pedido com range → várias REQUEST_DETAIL com o mesmo request_id e server_value conforme o range.
- Pedido servidor único → uma REQUEST_DETAIL com SERVER = S1, S2, etc.

---

## 2. Tabela CONFIG

Define parâmetros globais usados na geração de pedidos e detalhes.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | PK | |
| key | string | Ex.: `SERVER_ALL` |
| value | string/int | Ex.: `65` (quantidade de linhas quando SERVER=ALL) |

- **SERVER_ALL**: ao criar um REQUEST com SERVER=ALL, o Core gera REQUEST_DETAIL com 65 linhas (ou o valor de CONFIG), cada linha com SERVER 1, 2, … 65 (ou S1..S65, conforme convenção).

---

## 3. Entidades e tabelas (visão lógica)

### 3.1 REQUEST (cabeça do pedido)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | PK | Identificador único |
| status | enum | `PENDING` \| `PROCESSING` \| `FINISHED` \| `ERROR` \| `INVALID` |
| active_flag | 0/1 | 0 = disponível para device; 1 = device pegou (processando) |
| priority | enum | `CRITICAL` \| `HIGH` \| `NORMAL` \| `LOW` (ver seção 6) |
| order_type | enum | `ACC15` \| `ACC30` (nível de parada via OCR) |
| login | string | Credencial do pedido |
| password | string | Senha |
| nick | string | Nick |
| server | string | `ALL` \| `range_1` … `range_6` \| `S1` … `S65` |
| device_id | nullable | Preenchido quando um device pega o pedido (após 200) |
| created_at, updated_at | datetime | Auditoria |

- **Status do REQUEST** só vai para `FINISHED` quando **todas** as REQUEST_DETAIL estão `FINISHED`.
- Se **qualquer** detalhe for `ERROR` → status do REQUEST = `ERROR` (ao fechar o pedido).
- **Ordem de entrega:** por **priority** (CRITICAL primeiro, depois HIGH, NORMAL, LOW) e depois por **id** (momento gerado).

### 3.2 REQUEST_DETAIL (detalhes/linhas do pedido)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | PK | Identificador único (REQUEST_DETAIL_ID usado em outras tabelas) |
| request_id | FK | Referência ao REQUEST |
| line_index | int | Ordem da linha (ex.: 1 a 8 para range_1; 1 a 65 para ALL) |
| server_value | string | Posição/servidor da linha (ex.: "1" … "65" para ALL, ou "S3") |
| status | enum | `PENDING` \| `PROCESSING` \| `FINISHED` \| `ERROR` |
| device_id | nullable | Device que está processando este detalhe |
| updated_at | datetime | **Usado pelo batch de timeout** (se > 6h, devolve para PENDING) |

- O device atualiza **REQUEST_DETAIL** via PUT (status, etc.).
- Core deriva o status do REQUEST a partir dos status dos detalhes.
- **SERVER=ALL:** REQUEST.server = 'ALL' → Core gera 65 (ou CONFIG.SERVER_ALL) linhas em REQUEST_DETAIL com server_value 1, 2, … 65.

### 3.3 DEBUG_IMAGE (screenshot da Vision – débito técnico)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | PK | |
| request_id | FK | Opcional: associar ao pedido |
| request_detail_id | FK | Opcional: associar ao detalhe (REQUEST_DETAIL.id) |
| device_id | string | Quem enviou |
| image_path_or_blob | string/blob | Onde a imagem ficou (path ou ref) |
| detection_context | JSON | Coordenadas (x, y), template, confidence, etc. |
| created_at | datetime | |

- A cada detecção/click, Bot/Vision envia a imagem ao Core; Core persiste aqui.
- Usado para inspeção manual e para vincular ao log de erros (ver 3.5).

### 3.4 REQUEST_LOG (log de erros críticos + último click + exceção)

Objetivo: explicar **o que aconteceu** em um pedido/detalhe quando der erro, ligando **screenshot** (Vision) às **especificações** do pedido.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | PK | |
| request_id | FK | Pedido relacionado |
| request_detail_id | FK nullable | Detalhe relacionado (se aplicável) |
| device_id | string | Device que reportou |
| log_level | enum | `ERROR` \| `CRITICAL` (erros que importam para diagnóstico) |
| message | string | Mensagem de exceção ou resumo do erro |
| last_click | JSON | Último click antes do erro: `{ "x": 123, "y": 456 }` |
| debug_image_id | FK nullable | Referência a DEBUG_IMAGE (screenshot da detecção naquele momento) |
| created_at | datetime | |

- Quando ocorre erro crítico no device, o Bot envia: exception, último click (x, y) e referência à imagem de debug (ou o Core associa a última DEBUG_IMAGE daquele request_detail_id).
- Assim fica possível: “pedido X, detalhe Y, deu exceção Z, último click em (x,y), e **esta** é a imagem que a Vision tinha naquele momento” — tudo associado ao mesmo REQUEST/REQUEST_DETAIL.

### 3.5 Relação screenshot ↔ pedido

- **DEBUG_IMAGE:** armazena a imagem (path ou blob) + context (coordenadas, confidence) + request_id + request_detail_id.
- **REQUEST_LOG:** armazena erro, último click e **debug_image_id** (FK para DEBUG_IMAGE).
- Fluxo: a cada detecção/click o Core pode gravar DEBUG_IMAGE; quando há erro, o Bot envia log (message, last_click) e o Core associa ao último DEBUG_IMAGE daquele request_detail (ou envia explicitamente debug_image_id). Assim o screenshot fica relacionado às especificações do pedido e ao momento do erro.

---

## 4. Timeout / devolução (batch 6h)

- **Batch** (job agendado) verifica **REQUEST_DETAIL.updated_at**.
- Se um detalhe está em **PROCESSING** e `updated_at` > **6 horas** atrás:
  - Atualiza esse **REQUEST_DETAIL**: `status = PENDING`, `device_id = NULL`.
  - Se **todos** os detalhes daquele REQUEST voltaram a PENDING (nenhum mais em PROCESSING), atualiza o **REQUEST**: `status = PENDING`, `active_flag = 0`, `device_id = NULL`.
- Assim um device que caiu não “segura” o pedido para sempre; após 6h o pedido volta a ficar disponível para outro device.

---

## 5. Identificação do device

- **device_id:** enviado no corpo ou path (ex.: header `X-Device-Id` ou no payload).
- **Segurança:** header adicional (ex.: `Authorization: Bearer <token>` ou `X-API-Key`) validado pelo Core; o token/API key pode estar associado ao device_id no Core.
- Core valida: device_id + header de segurança antes de entregar pedido ou aceitar PUT.

---

## 6. Prioridade (ordem de entrega)

- **REQUEST.priority** define a ordem quando o device chama GET “próximo pedido”.
- Sugestão de valores (pode encurtar para 3 se preferir):

| priority | Uso sugerido |
|----------|------------------|
| `CRITICAL` | Urgente; processar antes de tudo |
| `HIGH` | Importante; antes de NORMAL e LOW |
| `NORMAL` | Padrão |
| `LOW` | Pode esperar |

- Ordenação: `ORDER BY priority (CRITICAL first), id ASC`. Se quiser só 3 níveis: `CRITICAL`, `NORMAL`, `LOW` (ou CRITICO, NAO_CRITICO, OUTRO em inglês: CRITICAL, NORMAL, OTHER).

---

## 7. Fluxos consolidados (atualizados)

### 7.1 Bot pega próximo pedido

1. Bot → Core: **GET** `/requests/next` (header: device_id + auth).
2. Core: busca REQUEST com `active_flag = 0` e `status IN (PENDING, PROCESSING)`, ordenado por **priority** e **id**; retorna **um** REQUEST + suas REQUEST_DETAIL.
3. Bot responde **HTTP 200**.
4. Core (ao confirmar 200): atualiza REQUEST (`active_flag = 1`, `device_id`, PENDING→PROCESSING) e opcionalmente marca REQUEST_DETAIL como PROCESSING conforme regra.

### 7.2 Device reporta progresso

- Bot → Core: **PUT** `/requests/{id}/details/{detailId}` com body: `{ "status": "FINISHED" }` ou `"ERROR"`.
- Core atualiza REQUEST_DETAIL.updated_at e status; quando todas as linhas terminam, atualiza REQUEST (FINISHED ou ERROR).

### 7.3 Erro crítico + log + screenshot

- Bot → Core: **POST** `/requests/{id}/log` (ou similar) com: `message`, `last_click`, opcionalmente `debug_image_id` ou a imagem (Core grava DEBUG_IMAGE e associa ao log).
- Core persiste em REQUEST_LOG e opcionalmente em DEBUG_IMAGE; assim o screenshot fica associado ao pedido e ao erro.

### 7.4 Batch de timeout (6h)

- Job periódico: para cada REQUEST_DETAIL com status PROCESSING e updated_at &lt; now - 6h, setar status = PENDING e device_id = NULL; se todos os detalhes do REQUEST ficaram PENDING, setar REQUEST.status = PENDING, active_flag = 0, device_id = NULL.

---

## 8. Revisão da modelagem e gaps

**Revisão crítica (o que faz sentido, o que está consistente e onde estão os gaps):** ver **[CORE-MODEL-REVIEW.md](CORE-MODEL-REVIEW.md)**.

Resumo dos pontos a fechar antes/durante implementação:

- **Concorrência:** dois devices fazendo GET ao mesmo tempo → Core deve garantir que só um receba o mesmo REQUEST (transação, SELECT FOR UPDATE, ou “reserva” ao gerar resposta).
- **Range 6:** definir explicitamente o conjunto “resto” (ex.: lista de números ou intervalo).
- **Convenção SERVER para ALL:** linhas com server_value "1"…"65" ou "S1"…"S65"; alinhar com o restante do sistema.

---

## 9. Ordem de implementação (foco: modelagem do banco primeiro)

### Fase 0 – Modelagem do banco de dados (primeiro)

**Definição das tabelas (somente schema):** **[CORE-DATABASE-TABLES.md](CORE-DATABASE-TABLES.md)**. A partir delas seguimos para regras, API e batch.

1. **Definir e criar tabelas**
   - CONFIG (key, value) — ex.: SERVER_ALL.
   - REQUEST (id, status, active_flag, priority, order_type, login, password, nick, server, device_id, created_at, updated_at).
   - REQUEST_DETAIL (id, request_id, line_index, server_value, status, device_id, updated_at).
   - DEBUG_IMAGE (id, request_id, request_detail_id, device_id, image_path_or_blob, detection_context, created_at).
   - REQUEST_LOG (id, request_id, request_detail_id, device_id, log_level, message, last_click, debug_image_id, created_at).
2. **Regras de negócio no modelo**
   - Geração de REQUEST_DETAIL quando REQUEST.server = ALL (ler CONFIG.SERVER_ALL, criar N linhas).
   - Derivação de REQUEST.status a partir dos status de REQUEST_DETAIL.

### Fase 1 – Core (API e batch)

3. **API REST do Core**
   - GET /requests/next (device_id + auth); ordenação por priority + id; atualização ao 200.
   - PUT /requests/{id}/details/{detailId} (status).
   - POST /requests (criação manual, ex.: Swagger); POST /requests/{id}/log (log de erro + last_click + debug_image_id ou imagem).
4. **Batch 6h**
   - Job que atualiza REQUEST_DETAIL e REQUEST para PENDING quando updated_at &gt; 6h.

### Fase 2 – Bot (cliente HTTP, reporte, log)

5. **Bot:** GET next, uso do payload, PUT por detalhe, POST log em erro crítico (com último click e referência à imagem se houver).

### Fase 3 – Debug image e Vision

6. **Persistência de screenshot:** POST que grava DEBUG_IMAGE a cada detecção/click; REQUEST_LOG referenciando debug_image_id quando houver erro.

### Fase 4 – BFF e gestão

7. **BFF + formulário** para criar REQUEST (e geração automática de REQUEST_DETAIL quando SERVER=ALL).

---

## 10. Resumo

- **REQUEST** tem **REQUEST_DETAIL** (antes REQUEST_LINE); SERVER=ALL só no REQUEST; detalhes gerados conforme CONFIG.SERVER_ALL (ex.: 65 linhas).
- **Batch 6h:** REQUEST_DETAIL.updated_at &gt; 6h em PROCESSING → detalhe e REQUEST voltam a PENDING.
- **Prioridade:** REQUEST.priority (CRITICAL, HIGH, NORMAL, LOW); ordem de entrega por priority + id.
- **Device:** device_id + header de segurança.
- **Log + screenshot:** REQUEST_LOG guarda erro, último click e debug_image_id; DEBUG_IMAGE guarda a imagem; assim o screenshot da Vision fica associado ao pedido e à causa do erro.
- **Ordem de implementação:** começar pela **modelagem do banco** (CONFIG, REQUEST, REQUEST_DETAIL, DEBUG_IMAGE, REQUEST_LOG), depois Core (API + batch), Bot, debug image, BFF.
