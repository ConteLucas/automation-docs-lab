# Proposta: relevância do fluxo e fluxo ORIGINAL

Este documento descreve o estado atual das tabelas `flow_step` e `flow_step_image`, o problema que o novo campo pretende resolver e opções de desenho (relevância / “fluxo original” / múltiplos fluxos editáveis sem interferir no que está em produção).

---

## 1. Estado atual das tabelas

### 1.1. `flow_step`

Representa **uma etapa** de um fluxo. O “fluxo” não tem tabela própria: é identificado pelo valor de **`flow_key`** (ex.: LOGIN, SELECT_SERVER, flow_local). A ordem da etapa dentro daquele fluxo é **`step_number`**.

| Coluna       | Tipo        | Restrições | Descrição |
|-------------|-------------|------------|-----------|
| id          | BIGINT      | PK, auto  | Identificador da etapa |
| flow_key    | VARCHAR(64) | NOT NULL  | Chave do fluxo; agrupa etapas (ex.: LOGIN, flow_local) |
| step_number | INT         | NOT NULL  | Número da etapa (1, 2, 3…) dentro do fluxo |
| name        | VARCHAR(128)| NULL      | Nome/descrição da etapa |
| created_at  | TIMESTAMP   | NOT NULL  | |
| updated_at  | TIMESTAMP   | NOT NULL  | |

**Constraint:** `UNIQUE (flow_key, step_number)` — em um mesmo `flow_key` não pode repetir `step_number`.

Hoje não existe nenhum campo que indique “ambiente” (RUNNING vs TESTE), “relevância” ou “qual fluxo é o original”.

---

### 1.2. `flow_step_image`

Representa **uma imagem** associada a **uma etapa** (`flow_step`). Uma etapa pode ter várias imagens (ordenadas por `step_img_number`).

| Coluna         | Tipo        | Restrições     | Descrição |
|----------------|-------------|----------------|-----------|
| id             | BIGINT      | PK, auto      | |
| flow_step_id   | BIGINT      | NOT NULL, FK  | Referência a `flow_step.id` |
| step_img_number| INT         | NOT NULL      | Ordem da imagem dentro da etapa (1, 2, …) |
| image_path     | VARCHAR(512)| NULL          | Caminho do arquivo no storage |
| image_data     | BLOB        | NULL          | Opcional (preferir image_path) |
| coordinates    | JSON/TEXT   | NULL          | Ex.: {"x":0,"y":0} |
| width          | INT         | NULL          | |
| height         | INT         | NULL          | |
| created_at     | TIMESTAMP   | NOT NULL      | |
| updated_at     | TIMESTAMP   | NOT NULL      | |

**Constraint:** `UNIQUE (flow_step_id, step_img_number)`.

A “relevância” ou “original” não está aqui; ela faria sentido no **fluxo** (ou na etapa), não na imagem em si.

---

### 1.3. Uso atual no front (VITE_ACTIVE_FLOW_GROUP)

- No front, a variável **`VITE_ACTIVE_FLOW_GROUP`** (ex.: `flow_local`) é usada só para **exibir** no header (“Environment: VITE_ACTIVE_FLOW_GROUP=flow_local”).
- Ela **não** é enviada ao backend e **não** filtra dados: o backend devolve todos os `flow_step` e o front agrupa por `flow_key`.
- Ou seja: hoje “qual fluxo está ativo/original” é **definido em build/deploy**, não no banco.

---

## 2. Objetivo da proposta

Você quer:

1. **Vários “tipos” de fluxo**  
   - Ex.: **RUNNING** = fluxo em uso, estável, não quer mexer.  
   - Ex.: **TESTE** = fluxo editável, para criar/alterar etapas, gerar rotas, testar, sem interferir no que já funciona.

2. **Marcar qual é o fluxo ORIGINAL**  
   - “O que está mais atualizado e funcionando” — em geral será um único “original” por contexto (ex.: por flow_key ou por flow_key + ambiente).

3. **Persistir isso no banco**  
   - Em vez de depender só de env (VITE_ACTIVE_FLOW_GROUP), ter um campo (ou tabela) que diga importância/relevância e “é o original?”.

Precisamos decidir **onde** guardar essa informação: por “fluxo” (por flow_key + variante) ou por etapa. Abaixo estão as opções.

---

## 3. Opções de desenho

### Opção A — Campo na tabela `flow_step` (variante por etapa)

- Adicionar em **`flow_step`** uma coluna, por exemplo:
  - **`flow_environment`** ou **`flow_relevance`** (VARCHAR ou ENUM): ex. `RUNNING`, `TESTE`, `BACKUP`.
- Opcional: outra coluna **`is_original`** (BOOLEAN) para marcar “este é o fluxo original (o mais atualizado)” para aquele `flow_key` + ambiente.

Regras:

- **Unicidade:** trocar para `UNIQUE (flow_key, flow_environment, step_number)` (ou `UNIQUE (flow_key, flow_relevance, step_number)`).
- Assim você pode ter:
  - flow_key=LOGIN, flow_environment=RUNNING, step_number=1 (original, não editar à vontade).
  - flow_key=LOGIN, flow_environment=TESTE, step_number=1 (cópia editável).
- **`flow_step_image`** continua ligada a `flow_step` por `flow_step_id`; não precisa de novo campo. Cada etapa já “herda” o ambiente/relevância da sua linha em `flow_step`.

Prós: simples, não cria tabela nova. Contras: “qual é o original?” fica espalhado por várias linhas (uma por etapa); para “um original por flow_key” precisaria de regra de negócio (ex.: só uma linha com `is_original = true` por (flow_key, flow_environment) ou por flow_key).

---

### Opção B — Nova tabela `flow` (recomendada para “um fluxo = um conjunto de etapas”)

- Criar tabela **`flow`**:
  - **id** (PK),
  - **flow_key** (ex.: LOGIN, flow_local),
  - **environment** ou **relevance** (ex.: RUNNING, TESTE),
  - **is_original** (BOOLEAN) — “este é o fluxo original/mais atualizado para este flow_key?”,
  - **name** (opcional),
  - created_at / updated_at.
- Em **`flow_step`**:
  - Trocar **`flow_key`** por **`flow_id`** (FK para `flow.id`).
  - Manter **step_number** com **UNIQUE (flow_id, step_number)**.

Assim:

- Um “fluxo” vira um registro em `flow` (ex.: LOGIN + RUNNING + is_original=true; LOGIN + TESTE + is_original=false).
- As etapas pertencem a um `flow_id`; as imagens continuam em `flow_step_image` por `flow_step_id`.
- O front (e o bot) podem filtrar por `flow.environment` e/ou `flow.is_original`.

Prós: modelo claro (“flow” é entidade), fácil listar “todos os fluxos” e “qual é o original”. Contras: migração (mover de flow_key para flow_id), e criar `flow` para cada combinação flow_key + environment que existir hoje.

---

### Opção C — Tabela de metadado por (flow_key, environment)

- Manter **`flow_step`** como está (com **flow_key**).
- Adicionar em **`flow_step`** uma coluna **`flow_environment`** (ex.: RUNNING, TESTE).
- Unicidade: **UNIQUE (flow_key, flow_environment, step_number)**.
- Criar uma tabela leve **`flow_metadata`** (ou `flow_original`):
  - **flow_key** (VARCHAR),
  - **flow_environment** (VARCHAR),
  - **is_original** (BOOLEAN),
  - UNIQUE (flow_key) ou (flow_key, flow_environment) conforme regra (“um original por flow_key” ou “um original por flow_key + environment”).

Assim você tem múltiplas “variantes” (flow_key + flow_environment) nas etapas, e em um lugar só diz qual é o original.

Prós: não introduz `flow_id`; metadado separado. Contras: regra de unicidade do original e consistência (sempre que houver etapas de um (flow_key, environment), existir linha em flow_metadata?) precisam ser bem definidas.

---

## 4. Resumo e recomendação

- **Estado atual:**  
  - **flow_step:** id, flow_key, step_number, name (+ timestamps). Fluxo = agrupamento por flow_key.  
  - **flow_step_image:** id, flow_step_id, step_img_number, image_path, coordinates, width, height (+ timestamps).  
  - “Ativo/original” hoje: só no front, via `VITE_ACTIVE_FLOW_GROUP`, sem persistência no banco.

- **Objetivo:**  
  - Ter variantes (ex.: RUNNING vs TESTE) e marcar qual é o **fluxo ORIGINAL** (o mais atualizado e funcionando), persistido no banco.

- **Recomendação:**  
  - Se quiser **pouca mudança** e continuar sem tabela `flow`: **Opção A** (campo `flow_environment` + opcional `is_original` em `flow_step`) ou **Opção C** (idem + tabela `flow_metadata` para “original”).  
  - Se quiser **modelo mais limpo** e evolução (vários fluxos, clones, histórico): **Opção B** (tabela `flow` + `flow_step.flow_id`).

Se você disser qual opção prefere (A, B ou C), posso detalhar o próximo passo: nomes exatos das colunas, DDL de migração e como o front/backend devem filtrar (ex.: “só RUNNING” ou “só is_original”).  
Se algo do que você imaginou (ex.: “só um original por flow_key” ou “original por flow_key + environment”) for diferente, podemos ajustar a regra em cima da opção escolhida.
