# Changelog — R00

## Added

- Core API Spring Boot com entidades de pedido, task, device, flow
- Bot Android com UIAutomator2 e integração REST
- Web CRM React
- Vision service (OCR)
- Schema PostgreSQL documentado em `CORE-DATABASE-TABLES.md`
- Seeds de permissão (ADM, DEV, MANAGER, SELLER)
- Modelo de 65 servidores e ranges compostos (range_3)

## Database

- Tabelas: `range_server`, `server`, `flow_step`, `flow_step_image`, `game_account`, `game_details_account`, `customer`, `sales_order`, `task`, `device`, `user_admin`, `permission`, RBAC auxiliar
- `game_account.login` único; detalhes por servidor em `game_details_account`

## Notas

- Deploy majoritariamente local; sem domínio público nesta fase.
