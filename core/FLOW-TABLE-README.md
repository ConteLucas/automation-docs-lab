# Tabela `flow` (collection)

## Existe? Onde fica?

A tabela **`flow`** existe no **mesmo banco de dados do Core** em que estão `flow_step`, `task`, `sales_order`, etc. Não fica em outro banco (ex.: “OCR”) nem em outro schema.

**Banco e porta (configuração do projeto):** banco **`automation_db`**, PostgreSQL na porta **5432** (ver `application.yml`, `application-local.properties` e `docker-compose.yml`). A tabela fica em `automation_db` (schema `public` no PostgreSQL).

Se você **não vê** a tabela `flow` no banco, crie assim:

1. **PostgreSQL (automation_db, porta 5432):** execute no DBeaver o script **`migration-flow-postgres.sql`**. Depois atualize a árvore: botão direito no schema **public** → **Refresh** (ou F5). O nome da tabela no PostgreSQL fica em minúsculo: **`flow`**.
2. **MySQL:** use `migration-add-flow-collection.sql` e `migration-flow-display-order.sql`.

## Definição

- **DDL:** `automation-db-lab/docs/CORE-DATABASE-DDL.sql` e `automation-db-lab/sql/`
- **Migração:** `migration-add-flow-collection.sql`.
- **Entidade JPA:** `FlowEntity` em `com.automation.core.adapter.out.persistence.entity`.

A tabela guarda as “collections” de fluxo (`flow_key`, `name_collection`, `is_original`, `display_order`). Os steps pertencem a um flow via `flow_step.flow_id` (FK para `flow.id`).
