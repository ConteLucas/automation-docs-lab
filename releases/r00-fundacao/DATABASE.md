# Banco de dados — R00 (baseline)

Referência canônica atualizada: [../../db/ARCHITECTURE.md](../../db/ARCHITECTURE.md).

## Tabelas introduzidas

| Grupo | Tabelas |
|-------|---------|
| Catálogo | `range_server`, `server`, `game_account`, `game_details_account` |
| Flows | `flow_step`, `flow_step_image` |
| CRM | `customer`, `sales_order` |
| Execução | `task`, `device`, `debug_image`, `order_task_log` |
| Auth | `user_admin`, `permission`, `permission_function`, `permission_function_grant`, `user_permission` |

## Permissões (R00)

`ADM`, `DEV`, `MANAGER`, `SELLER` — sem perfis de marketplace.

## Diagrama ER (subset R00)

```mermaid
erDiagram
    range_server ||--o{ server : range_server_id
    range_server ||--o{ sales_order : range_server_id
    customer ||--o{ sales_order : customer_id
    sales_order ||--o{ task : sales_order_id
    game_account ||--o{ game_details_account : game_account_id
    game_account ||--o{ task : game_account_id
    device ||--o{ task : device_id
    flow_step ||--o{ flow_step_image : flow_step_id
    flow_step ||--o{ task : flow_step_id
    user_admin ||--o{ sales_order : user_admin_id
```
