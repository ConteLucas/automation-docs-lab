# Endpoint de Approval: Sales Order → Tasks (uma por linha do range)

## Contexto

- **Sales Order** tem um **range** (`range_server_id`). O range tem um `value` (ex.: 5).
- **tasks_total** = `accounts_count` × `range.value` (ex.: 10 contas × 5 = **50 tarefas**).
- Cada **Task** é uma linha: `sales_order_id`, `game_account_id`, `server_value`, `device_id`, `status_task`, etc.

A ideia: na tela de **Tasks** (front), uma tarefa (ou a ordem) tem um botão **Approval**. Ao clicar, chama-se um endpoint que, a partir da **sales order**, gera **uma task por “linha”** do total do range (ou seja, `tasks_total` linhas).

---

## Onde fica o endpoint

Duas opções coerentes:

1. **Em Tasks** (recomendado para “ação sobre ordem gerando várias tasks”):
   - `POST /api/tasks/approve-from-order`
   - Body: identifica a sales order e as linhas (ver abaixo).

2. **Em Sales Order** (alternativa):
   - `POST /api/sales-orders/{id}/approve`
   - Body: lista de linhas para criar as tasks.

Ambos fazem a mesma coisa: recebem a sales order (ou id) e criam N tasks, **uma por linha**.

---

## Modelo atual

- **SalesOrder**: `tasks_total` = `accounts_count` × `range_server.value`; já está calculado na criação/edição da ordem.
- **Task**: obrigatório `sales_order_id`, `game_account_id`, `server_value`, `device_id`, `status_task`. Não dá para criar task “vazia” só com ordem.

Por isso: **cada linha criada no approval precisa de** `gameAccountId`, `serverValue`, `deviceId` (além da ordem).

---

## Proposta de contrato (exemplo em Tasks)

### Opção A – Front envia as N linhas

O front já sabe (ou monta) quantas linhas criar = `tasks_total` da sales order. Para cada linha envia uma conta, server_value e device (ex.: escolhidos em um grid ou alocados automaticamente no front).

**Endpoint (em Tasks):**

```
POST /api/tasks/approve-from-order
Content-Type: application/json
```

**Body:**

```json
{
  "salesOrderId": 123,
  "lines": [
    { "gameAccountId": 1, "serverValue": "S56", "deviceId": 10 },
    { "gameAccountId": 2, "serverValue": "S56", "deviceId": 10 },
    …
  ]
}
```

**Regras no backend:**

1. Buscar a sales order por `salesOrderId`; se não existir → 404.
2. Verificar se a ordem está em estado permitido (ex.: `PENDING` ou `APPROVED`).
3. Calcular o esperado: `expected = order.getAccountsCount() * order.getRangeServer().getValue()` (ou usar `order.getTasksTotal()`).
4. Validar: `lines.size() == expected` (ou `<= expected`, conforme regra de negócio).
5. Para cada item em `lines`:
   - Validar `gameAccountId`, `deviceId` existem e (se houver regra) pertencem ao escopo da ordem (ex.: server no mesmo range).
   - Criar uma **Task** com:
     - `salesOrder` = ordem
     - `gameAccount`, `serverValue`, `device` = do item
     - `statusTask` = `"PENDING"` (ou `"APPROVED"`)
   - Respeitar a constraint única `(sales_order_id, game_account_id, server_value)` (não duplicar mesma conta+server na mesma ordem).
6. Opcional: atualizar a sales order (ex.: `status_order` = `"APPROVED"`, `tasks_completed` = 0).
7. Retornar: 201 + lista de `TaskResponse` criadas (ou só o count e ids).

Assim: **uma chamada, uma task por linha**, com a sales order e o total do range já considerados.

---

### Opção B – Só passar a sales order (backend aloca)

Aqui o backend precisaria ter regra para **alocar** N `(game_account, server_value, device)` automaticamente (ex.: buscar contas e devices disponíveis no `server_scope` da ordem e preencher até `tasks_total` linhas).

**Endpoint (em Tasks):**

```
POST /api/tasks/approve-from-order
Content-Type: application/json

{ "salesOrderId": 123 }
```

**Regras no backend:**

1. Carregar a sales order e o range; calcular `tasks_total`.
2. Buscar game_accounts (e devices) elegíveis (ex.: por range, por customer, disponíveis).
3. Criar exatamente `tasks_total` tasks, atribuindo conta e device conforme a regra (ex.: round-robin, primeiro disponível).
4. Se não houver contas/devices suficientes → 409 ou 400 com mensagem clara.

Isso exige definir bem no Core como “disponível” e como alocar; por isso a **Opção A** costuma ser mais simples de implementar primeiro.

---

## Fluxo no front (Tasks)

1. Usuário vê uma tarefa (ou um card da sales order) com botão **Approval**.
2. O front já tem (ou busca) a **sales order** e o **tasks_total** (ex.: `order.tasksTotal` ou `accountsCount * range.value`).
3. **Se Opção A:** o front monta a lista de `lines` (gameAccountId, serverValue, deviceId) com tamanho = `tasks_total` (ex.: escolhendo contas e devices em um grid/modal).
4. Chama:
   - `POST /api/tasks/approve-from-order` com `{ salesOrderId, lines }` (Opção A), ou  
   - `POST /api/tasks/approve-from-order` com `{ salesOrderId }` (Opção B).
5. Backend cria **uma task por linha** (total do range) e retorna sucesso (e lista de tasks, se quiser).
6. Front atualiza a lista de tasks (e pode atualizar status da ordem).

---

## Resumo

- **Onde:** endpoint em **Tasks** (ou em Sales Order), por exemplo `POST /api/tasks/approve-from-order`.
- **Entrada:** sales order (id) +, na Opção A, uma lista de `lines` com `gameAccountId`, `serverValue`, `deviceId`.
- **O que faz:** considera a sales order e o range; gera **uma task por linha** até o total do range (`tasks_total`).
- **Front:** botão Approval na tela de Tasks chama esse endpoint; o número de linhas é o `tasks_total` da sales order (já considerando o range x).

Se quiser, o próximo passo é implementar no `TaskController` (ou em `SalesOrderController`) o `POST /api/tasks/approve-from-order` com a Opção A (body com `salesOrderId` + `lines`).
