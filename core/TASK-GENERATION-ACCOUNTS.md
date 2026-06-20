# Contas na geração de tarefas vs pedido

Hoje o fluxo implementado é:

1. **Pedido** é criado (cliente, range, tipo ACC15/ACC30, quantidade de contas planejada, etc.).
2. Na **geração de tarefas**, o operador escolhe **uma conta livre (LIVRE)** e o **flow** (ou padrão FLOW15/FLOW30).

Isso cobre dois cenários de negócio com o mesmo endpoint:

- **Contas “próprias” do pedido**: o representante já cadastrou as contas e, na hora de gerar, escolhe qual conta usar naquele lote (uma conta por conjunto de tarefas do range, como hoje).
- **Contas do cadastro geral**: mesma coisa — a conta já existe em `game_account` e é selecionada no modal.

### Evolução possível (pedido amarra contas)

Se quiser que **o pedido já traga** quais contas usar (sem escolher de novo na geração):

- Adicionar ao modelo de **sales_order** algo como lista de `game_account_id` (tabela N:N ou JSON, conforme regra de negócio).
- Na geração: se o pedido tiver contas vinculadas, **validar** quantidade vs `range.value` / `accounts_count` e **não** exigir `gameAccountId` no body (ou exigir só quando o pedido não tiver vínculo).

Isso é extensão de API/schema; o desacoplamento **device na claim** permanece igual.
