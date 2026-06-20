# automation-db-lab — Arquitetura do Banco de Dados

Visão completa do modelo relacional PostgreSQL da plataforma DDT. O schema é **gerado e gerenciado pelo Core** (JPA/Hibernate `ddl-auto`). Este repositório serve como referência de planejamento, DDL de estudo e seeds.

---

## Diagrama ER — Visão Macro

```mermaid
erDiagram
    range_server {
        bigint id PK
        varchar range_key UK "ALL, range_1..range_6"
        int value "qtd servidores do range"
        varchar description "segmentos ex: 1-9"
        timestamp created_at
        timestamp updated_at
    }

    server {
        bigint id PK
        varchar server_number UK "1..65"
        bigint range_server_id FK
        varchar image_path "template OCR"
        varchar name "s1..s65"
        timestamp created_at
        timestamp updated_at
    }

    flow_step {
        bigint id PK
        varchar flow_key "LOGIN, SELECT_SERVER..."
        int step_number "ordem dentro do fluxo"
        varchar name
        timestamp created_at
        timestamp updated_at
    }

    flow_step_image {
        bigint id PK
        bigint flow_step_id FK
        varchar image_path "path no storage/S3"
        blob image_data "opcional binário"
        json coordinates "{x, y}"
        int width
        int height
        int step_img_number "ordem dentro do step"
        varchar worker_action "CLICK, WAIT_APPEAR, GOTO..."
        json worker_action_config
        timestamp created_at
        timestamp updated_at
    }

    game_account {
        bigint id PK
        varchar login UK
        varchar password "AES-256-GCM em prod (v1: prefix)"
        timestamp created_at
        timestamp updated_at
    }

    game_details_account {
        bigint id PK
        bigint game_account_id FK
        varchar nick
        varchar server "s1..s65"
        int xp
        int level
        timestamp created_at
        timestamp updated_at
    }

    customer {
        bigint id PK
        varchar name
        varchar contact_number
        varchar pix_key
        varchar profile "REVENDEDOR, COMPRADOR"
        int total_purchases
        int closed_purchases
        int open_purchases
        int cancelled_purchases
        text description
        timestamp deleted_at "soft delete"
        timestamp created_at
        timestamp updated_at
    }

    sales_order {
        bigint id PK
        bigint customer_id FK
        bigint range_server_id FK
        bigint user_admin_id FK
        varchar description
        varchar status_order "PENDING, PROCESSING, FINISHED, ERROR"
        varchar priority "CRITICAL, HIGH, NORMAL, LOW"
        varchar order_type "ACC15, ACC30"
        int accounts_count
        int tasks_total
        int tasks_completed
        tinyint active_flag
        varchar server_scope
        timestamp created_at
        timestamp updated_at
    }

    task {
        bigint id PK
        bigint sales_order_id FK
        bigint game_account_id FK
        bigint device_id FK
        bigint flow_step_id FK
        varchar server_value "s1..s65"
        varchar status_task "PENDING, PROCESSING, FINISHED, ERROR"
        timestamp created_at
        timestamp updated_at
    }

    device {
        bigint id PK
        varchar identifier UK "Android ID"
        varchar name
        varchar api_key_hash "BCrypt"
        varchar status "ATIVO, INATIVO, DEPRECADO"
        timestamp deleted_at "soft delete"
        timestamp created_at
        timestamp updated_at
    }

    debug_image {
        bigint id PK
        bigint task_id FK
        varchar image_path
        json detection_context "{x, y, template, confidence}"
        timestamp created_at
        timestamp updated_at
    }

    order_task_log {
        bigint id PK
        bigint task_id FK
        varchar log_level "CRITICAL"
        text message "stack trace"
        json last_click "{x, y}"
        varchar log_file_path
        timestamp created_at
        timestamp updated_at
    }

    user_admin {
        bigint id PK
        varchar login UK
        varchar password_hash "BCrypt ($2a$)"
        varchar name
        varchar email
        boolean active
        bigint permission_id FK
        timestamp deleted_at "soft delete"
        timestamp created_at
        timestamp updated_at
    }

    permission {
        bigint id PK
        varchar name UK "ADM, DEV, MANAGER, SELLER"
        timestamp created_at
        timestamp updated_at
    }

    permission_function {
        bigint id PK
        varchar code UK "VIEW_ORDERS, CREATE_ORDERS..."
        varchar description
        timestamp created_at
        timestamp updated_at
    }

    permission_function_grant {
        bigint permission_id FK
        bigint permission_function_id FK
    }

    user_permission {
        bigint user_id FK
        bigint permission_id FK
    }

    flow {
        bigint id PK
        varchar key UK "LOGIN, SELECT_SERVER..."
        varchar name
        bigint collection_id FK
        timestamp created_at
        timestamp updated_at
    }

    collection {
        bigint id PK
        varchar name
        varchar description
        timestamp created_at
        timestamp updated_at
    }

    range_server ||--o{ server : "range_server_id"
    range_server ||--o{ sales_order : "range_server_id"
    flow_step ||--o{ flow_step_image : "flow_step_id"
    flow_step ||--o{ task : "flow_step_id"
    flow ||--o{ flow_step : "flow_id"
    collection ||--o{ flow : "collection_id"
    game_account ||--o{ game_details_account : "game_account_id"
    game_account ||--o{ task : "game_account_id"
    customer ||--o{ sales_order : "customer_id"
    user_admin ||--o{ sales_order : "user_admin_id"
    sales_order ||--o{ task : "sales_order_id"
    device ||--o{ task : "device_id"
    task ||--o{ debug_image : "task_id"
    task ||--o{ order_task_log : "task_id"
    permission ||--o{ user_admin : "permission_id"
    permission ||--o{ permission_function_grant : "permission_id"
    permission ||--o{ user_permission : "permission_id"
    permission_function ||--o{ permission_function_grant : "permission_function_id"
    user_admin ||--o{ user_permission : "user_id"
```

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
        UA["user_admin\nBCrypt password\nrole principal"]
        PERM["permission\nADM, DEV, MANAGER, SELLER"]
        PF["permission_function\nVIEW_ORDERS, CREATE_ORDERS..."]
        PFG["permission_function_grant\nmatriz role × função"]
        UP["user_permission\nN:N user ↔ role"]
        UA -->|FK| PERM
        UP -->|N:N| UA
        UP -->|N:N| PERM
        PFG -->|N:N| PERM & PF
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
| **Catálogo de Jogo** | `range_server`, `server`, `game_account`, `game_details_account` |
| **Automação (Flows)** | `collection`, `flow`, `flow_step`, `flow_step_image` |
| **CRM** | `customer`, `sales_order` |
| **Execução** | `task`, `device`, `debug_image`, `order_task_log` |
| **Auth/RBAC** | `user_admin`, `permission`, `permission_function`, `permission_function_grant`, `user_permission` |

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
automation-db-lab/
├── docs/
│   ├── ARCHITECTURE.md        # este arquivo
│   ├── CORE-DATABASE-TABLES.md  # definição canônica das tabelas
│   ├── CORE-DATABASE-DDL.sql  # DDL de referência
│   ├── FLOW-CONTRACT.md       # contrato da tabela flow
│   └── modeling/
│       └── automation-ddt.drawio  # diagrama visual
├── sql/
│   ├── core/
│   │   ├── massa.sql          # dados iniciais (dev)
│   │   ├── init.sql           # script inicial
│   │   ├── schema-only.sql    # apenas DDL
│   │   └── V2-V11__*.sql      # migrations históricas
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
