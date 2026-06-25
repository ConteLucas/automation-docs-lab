# automation-db-lab — Arquitetura do Banco de Dados

Visão completa do modelo relacional PostgreSQL da plataforma DDT. O schema é **gerado e gerenciado pelo Core** (JPA/Hibernate `ddl-auto`). Este repositório serve como referência de planejamento, DDL de estudo e seeds.

**Histórico por release:** [releases/INDEX.md](../releases/INDEX.md) — deltas em `r03-marketlab/DATABASE.md` e `r04-producao-identidade/DATABASE.md`.

---

## Diagrama ER — Visão Completa

```mermaid
erDiagram
  range_server {
    bigint id PK
    varchar range_key UK
    int value
    varchar description
  }
  server {
    bigint id PK
    varchar server_number UK
    bigint range_server_id FK
    varchar image_path
    varchar name
  }
  collection {
    bigint id PK
    varchar collection_key UK
    varchar name_collection
    varchar default_flow_key
    int display_order
    varchar version
    varchar content_hash
    boolean is_original
  }
  flow {
    bigint id PK
    bigint collection_id FK
    varchar flow_key
    varchar name
    int display_order
    varchar version
    varchar content_hash
  }
  flow_step {
    bigint id PK
    bigint flow_id FK
    int step_number
    varchar step_key
    varchar flow_key
    varchar version
    varchar content_hash
  }
  flow_step_image {
    bigint id PK
    bigint flow_step_id FK
    int step_img_number
    varchar image_path
    varchar worker_action
    varchar effect
    varchar transition_flow_key
    int transition_from_step_number
    varchar version
    varchar content_hash
  }
  game_account {
    bigint id PK
    varchar login UK
    varchar password
    bigint customer_id FK
    bigint sales_order_id FK
    varchar account_status
    varchar game
    boolean draft
    boolean marketplace_featured
    decimal price
    boolean price_on_request
  }
  game_details_account {
    bigint id PK
    bigint game_account_id FK
    varchar nick
    varchar server
    int level
    int xp
  }
  game_account_image {
    bigint id PK
    bigint game_account_id FK
    varchar image_path
    int sort_order
  }
  customer {
    bigint id PK
    varchar name
    varchar profile
    bigint created_by_user_id
    timestamp deleted_at
  }
  sales_order {
    bigint id PK
    bigint customer_id FK
    bigint user_admin_id FK
    bigint range_server_id FK
    varchar status_order
    varchar order_type
    int accounts_count
    int tasks_total
    int tasks_completed
  }
  task {
    bigint id PK
    bigint sales_order_id FK
    bigint game_account_id FK
    bigint collection_id FK
    bigint device_id FK
    varchar server_value
    varchar status_task
  }
  device {
    bigint id PK
    varchar identifier UK
    varchar status
    varchar alias
    bigint user_admin_id FK
    timestamp deleted_at
  }
  debug_image {
    bigint id PK
    bigint task_id FK
    varchar image_path
    json detection_context
  }
  order_task_log {
    bigint id PK
    bigint task_id FK
    varchar log_level
    text message
    varchar log_file_path
  }
  user_admin {
    bigint id PK
    varchar login UK
    varchar password_hash
    varchar email
    boolean email_verified
    bigint permission_id FK
    varchar oauth_provider
    varchar avatar_path
    bigint manager_user_id
    timestamp deleted_at
  }
  permission {
    bigint id PK
    varchar name UK
  }
  permission_function {
    bigint id PK
    varchar code UK
    varchar description
  }
  permission_function_grant {
    bigint permission_id FK
    bigint permission_function_id FK
  }
  user_permission {
    bigint user_id FK
    bigint permission_id FK
  }
  ads_service_provider {
    bigint id PK
    bigint user_id FK
    varchar game_slug
    varchar display_name
    text services_json
    boolean active
    boolean featured
  }
  ads_service_provider_review {
    bigint id PK
    bigint provider_id FK
    bigint reviewer_user_id FK
    int rating
    text comment
  }
  marketplace_listing {
    bigint id PK
    bigint created_by_user_id FK
    varchar game_slug
    decimal price
    boolean draft
    boolean featured
    varchar status
  }
  marketplace_listing_image {
    bigint id PK
    bigint listing_id FK
    varchar image_path
    int sort_order
  }
  marketplace_listing_proposal {
    bigint id PK
    bigint listing_id FK
    bigint buyer_user_id FK
    decimal offered_price
  }
  marketplace_seller_review {
    bigint id PK
    bigint seller_user_id FK
    bigint reviewer_user_id FK
    bigint listing_id
    int rating
    text comment
  }
  wallet_settings {
    bigint id PK
    int price_per_server_cents
    varchar default_range_key
  }
  wallet {
    bigint id PK
    bigint user_id FK_UK
    bigint balance_cents
  }
  wallet_transaction {
    bigint id PK
    bigint wallet_id FK
    varchar type
    bigint amount_cents
    bigint balance_after_cents
    varchar reference_type
    bigint reference_id
  }
  user_notification {
    bigint id PK
    bigint user_id FK
    varchar type
    varchar title
    text body
    json payload
    timestamp read_at
  }
  chat_read_status {
    bigint id PK
    bigint user_id FK
    varchar channel
    bigint context_id
    bigint peer_user_id
    timestamp read_at
  }
  email_confirmation_token {
    bigint id PK
    bigint user_id FK
    varchar token UK
    timestamp expires_at
  }
  password_reset_token {
    bigint id PK
    bigint user_id FK
    varchar token UK
    timestamp expires_at
  }
  site_config {
    varchar config_key PK
    text config_value
  }
  lab_access_request {
    bigint id PK
    varchar lab
    varchar login
    varchar status
    bigint reviewed_by_user_id
    bigint created_user_id
  }

  range_server ||--o{ server : range_server_id
  range_server ||--o{ sales_order : range_server_id
  collection ||--o{ flow : collection_id
  flow ||--o{ flow_step : flow_id
  flow_step ||--o{ flow_step_image : flow_step_id
  collection ||--o{ task : collection_id
  customer ||--o{ sales_order : customer_id
  customer ||--o{ game_account : customer_id
  sales_order ||--o{ task : sales_order_id
  sales_order ||--o{ game_account : sales_order_id
  game_account ||--o{ game_details_account : game_account_id
  game_account ||--o{ game_account_image : game_account_id
  game_account ||--o{ task : game_account_id
  device ||--o{ task : device_id
  task ||--o{ debug_image : task_id
  task ||--o{ order_task_log : task_id
  user_admin ||--o{ sales_order : user_admin_id
  user_admin ||--o{ device : user_admin_id
  user_admin ||--o{ customer : created_by_user_id
  user_admin ||--o{ game_account : created_by_user_id
  user_admin }o--|| permission : permission_id
  user_admin ||--o{ user_permission : user_id
  permission ||--o{ user_permission : permission_id
  permission ||--o{ permission_function_grant : permission_id
  permission_function ||--o{ permission_function_grant : permission_function_id
  user_admin ||--o| ads_service_provider : user_id
  ads_service_provider ||--o{ ads_service_provider_review : provider_id
  user_admin ||--o{ marketplace_listing : created_by_user_id
  marketplace_listing ||--o{ marketplace_listing_image : listing_id
  marketplace_listing ||--o{ marketplace_listing_proposal : listing_id
  user_admin ||--|| wallet : user_id
  wallet ||--o{ wallet_transaction : wallet_id
  user_admin ||--o{ user_notification : user_id
  user_admin ||--o{ chat_read_status : user_id
  user_admin ||--o{ email_confirmation_token : user_id
  user_admin ||--o{ password_reset_token : user_id
```

> **Escopo atual:** 35 tabelas das entidades JPA do Core. Removidas do modelo atual: `flow_transition` (V10) e `marketplace_listing_question` (V28).

> **Releases:** CUSTOMER/SERVICE_PROVIDER e marketplace em [releases/r03-marketlab/DATABASE.md](../releases/r03-marketlab/DATABASE.md); OAuth em [releases/r04-producao-identidade/DATABASE.md](../releases/r04-producao-identidade/DATABASE.md).

---

## Mapa de Domínios

```mermaid
graph TB
    subgraph catalog["Catálogo de Jogo"]
        style catalog fill:#dbeafe,stroke:#3b82f6
        RS["range_server\n7 ranges (ALL+6)\n65 servidores total"]
        SV["server\n65 registros (s1-s65)\nimage_path para OCR"]
        GA["game_account\nlogin + senha AES"]
        GDA["game_details_account\nnick, server, level, xp\nUNIQUE(account, server)"]
        RS --> SV
        GA -->|1:N| GDA
    end

    subgraph automation["Automação (Flows)"]
        style automation fill:#ede9fe,stroke:#7c3aed
        COLL["collection\nagrupa flows relacionados"]
        FL["flow\nidentifica um fluxo\n(LOGIN, SELECT_SERVER...)"]
        FS["flow_step\netapa do fluxo\nstep_number ASC"]
        FSI["flow_step_image\ntemplate PNG + worker_action\nstep_img_number ASC"]
        COLL -->|1:N| FL -->|1:N| FS -->|1:N| FSI
    end

    subgraph crm["CRM"]
        style crm fill:#d1fae5,stroke:#059669
        CUST["customer\ncliente/revendedor\ncontadores de compras"]
        SO["sales_order\npedido de venda\nstatus_order + tasks_total/completed"]
        CUST -->|1:N| SO
    end

    subgraph execution["Execução"]
        style execution fill:#fef3c7,stroke:#d97706
        TSK["task\n1 por (order, conta, servidor)\nstatus_task + device_id"]
        DEV["device\nAndroid bot\napi_key_hash BCrypt"]
        DI["debug_image\nscreenshot na falha"]
        OTL["order_task_log\nerro crítico que parou o serviço"]
        SO -->|N tasks| TSK
        GA -->|1 conta| TSK
        SV -->|server_value| TSK
        DEV -->|1 device| TSK
        TSK -->|1:N| DI
        TSK -->|1:N| OTL
    end

    subgraph auth["Auth & RBAC"]
        style auth fill:#fce7f3,stroke:#db2777
        UA["user_admin\nBCrypt ou OAuth\nrole principal"]
        PERM["permission\nADM, DEV, MANAGER, SELLER\nCUSTOMER, SERVICE_PROVIDER"]
        PF["permission_function\nVIEW_ORDERS, CREATE_ORDERS..."]
        PFG["permission_function_grant\nmatriz role × função"]
        UP["user_permission\nN:N user ↔ role"]
        UA -->|FK| PERM
        UP -->|N:N| UA
        UP -->|N:N| PERM
        PFG -->|N:N| PERM & PF
    end

    subgraph marketlab["MarketLAB (R03+)"]
        style marketlab fill:#fef3c7,stroke:#d97706
        ASP["ads_service_provider\nprestador de serviços"]
        ASR["ads_service_provider_review\navaliações"]
        UA -->|1:0..1| ASP
        ASP -->|1:N| ASR
        GA -->|marketplace_featured| MKT_CAT["catálogo público"]
    end

    SO --> RS
    UA -->|cria| SO
```

---

## Fluxo de Geração de Tasks (cenário 30×8)

```mermaid
flowchart TD
    REQ["Operador cria sales_order\n(customer, range=range_1, type=ACC30, accounts_count=30)"]

    VALIDATE["Core valida:\nSELECT COUNT(*) FROM game_account ga\nJOIN game_details_account gda ON gda.game_account_id = ga.id\nWHERE gda.level < 30\n≥ 30?"]

    VALIDATE -->|não| ERR["HTTP 409 — contas insuficientes"]
    VALIDATE -->|sim| SELECT_ACCOUNTS

    SELECT_ACCOUNTS["SELECT 30 game_accounts\nWHERE level < 30\nORDER BY level ASC LIMIT 30"]

    SELECT_SERVERS["SELECT servers\nWHERE range_server_id = range_1\n= 8 servidores (s1–s9 menos 1)"]

    SELECT_DEVICE["SELECT 1 device\nWHERE status = ATIVO\nORDER BY tasks pendentes ASC\n= device escolhido"]

    CREATE_TASKS["INSERT 240 tasks\n30 contas × 8 servidores\nmesmo device_id\nstatus_task = PENDING"]

    UPDATE_ORDER["UPDATE sales_order\nSET tasks_total = 240\nstatus_order = PENDING"]

    REQ --> VALIDATE
    VALIDATE --> SELECT_ACCOUNTS --> SELECT_SERVERS --> SELECT_DEVICE --> CREATE_TASKS --> UPDATE_ORDER
```

---

## Ciclo de Status de uma Task

```mermaid
stateDiagram-v2
    [*] --> PENDING : gerada ao criar sales_order

    PENDING --> PROCESSING : bot claim-next\n(POST /api/tasks/claim-next)

    PROCESSING --> FINISHED : bot reporta sucesso\n(PATCH status FINISHED)
    PROCESSING --> ERROR : exceção terminal\n(PATCH status ERROR)
    PROCESSING --> PENDING : timeout 6h\n(batch job)

    FINISHED --> [*]
    ERROR --> PENDING : retry manual
    ERROR --> [*]
```

---

## Índices e Constraints Críticos

```mermaid
graph LR
    subgraph unique["UNIQUE Constraints"]
        U1["range_server(range_key)"]
        U2["server(server_number)"]
        U3["game_account(login)"]
        U4["game_details_account(game_account_id, server)"]
        U5["task(sales_order_id, game_account_id, server_value)"]
        U6["flow_step(flow_key, step_number) — recomendado"]
        U7["permission(name)"]
        U8["user_admin(login)"]
        U9["device(identifier)"]
    end

    subgraph indexes["Índices de Performance"]
        I1["task(device_id, status_task)\nclaim-next query"]
        I2["task(status_task, updated_at)\nbatch timeout"]
        I3["task(sales_order_id)\nlistar tasks da ordem"]
        I4["debug_image(task_id, created_at)\ncorrelacionar com logs"]
        I5["order_task_log(task_id)"]
    end
```

---

## Tabelas por Módulo

| Módulo | Tabelas |
|--------|---------|
| **Catálogo de Jogo** | `range_server`, `server`, `game_account`, `game_details_account`, `game_account_image` |
| **Automação (Flows)** | `collection`, `flow`, `flow_step`, `flow_step_image` |
| **CRM** | `customer`, `sales_order` |
| **Execução** | `task`, `device`, `debug_image`, `order_task_log` |
| **Auth/RBAC** | `user_admin`, `permission`, `permission_function`, `permission_function_grant`, `user_permission` |
| **ProviderLAB** | `ads_service_provider`, `ads_service_provider_review` |
| **MarketLAB** | `marketplace_listing`, `marketplace_listing_image`, `marketplace_listing_proposal`, `marketplace_seller_review` |
| **Wallet** | `wallet_settings`, `wallet`, `wallet_transaction` |
| **Identidade / notificações** | `email_confirmation_token`, `password_reset_token`, `user_notification`, `chat_read_status` |
| **Plataforma** | `site_config`, `lab_access_request` |

---

## Segurança dos Dados

| Campo | Mecanismo | Onde |
|-------|-----------|------|
| `user_admin.password_hash` | BCrypt ($2a$) | Postgres |
| `game_account.password` | AES-256-GCM (prefixo `v1:`) em prod; plaintext em dev | Postgres |
| `device.api_key_hash` | BCrypt | Postgres |
| Imagens de templates | Path referenciando S3/local | Postgres (só o path) |

---

## Estrutura do Repositório

```
automation-docs-lab/db/
├── ARCHITECTURE.md              # este arquivo
├── docs/
│   ├── INDEX.md
│   ├── CORE-DATABASE-TABLES.md  # definição canônica das tabelas
│   ├── CORE-DATABASE-DDL.sql    # DDL de referência
│   ├── FLOW-CONTRACT.md         # contrato L1–L4
│   └── modeling/
│       └── automation-ddt.drawio  # diagrama visual (./generate-ddt-drawio.sh)
automation-db-lab/
├── sql/
│   ├── core/
│   │   ├── massa.sql          # dados iniciais (dev)
│   │   ├── init.sql           # script inicial
│   │   ├── schema-only.sql    # apenas DDL
│   │   └── V2-V30__*.sql      # migrations históricas
│   ├── migrations/            # alterações pontuais
│   └── reports/               # queries de relatório (read-only)
└── seeds/
    └── permission-seed.json   # roles/functions (carregado pelo Core ao iniciar)
```

---

## ddl-auto por Ambiente

| Perfil | `ddl-auto` | Efeito |
|--------|------------|--------|
| `local` | `update` | Ajusta schema sem drop |
| `dev` / `prod` / `docker` | `validate` | Só valida; falha se BD ≠ entidades |
| EC2 prod lab | `update` (env override) | Ajusta automaticamente |
