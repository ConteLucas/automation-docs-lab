# automation-core-lab — Arquitetura

Backend central da Plataforma DDT. API REST em Spring Boot com arquitetura Hexagonal (Ports & Adapters), responsável por toda a lógica de negócio, orquestração de tasks, gestão de contas/devices/pedidos e persistência em PostgreSQL.

---

## Visão Macro

```mermaid
graph TB
    subgraph clients["Clientes"]
        WEB["automation-web-lab\nReact CRM"]
        BOT["automation-bot-lab\nAndroid Worker"]
        DEVICE["automation-device-lab\nDesktop Tool"]
    end

    subgraph core["automation-core-lab (Spring Boot :8080/8081)"]
        direction TB
        subgraph adapters_in["Adapter IN — Web Layer"]
            CTRL["Controllers REST\n(Auth, Task, Order, Flow, Device...)"]
            SEC["Security Filter\n(JWT + API Key)"]
        end

        subgraph app["Application Layer"]
            SVC["Services\n(TaskService, SalesOrderService,\nFlowService, GameAccountService...)"]
            STARTUP["Startup / Seed\n(PermissionSeedRunner, CoreApplicationBootstrap)"]
        end

        subgraph domain["Domain Layer"]
            MODEL["Domain Models\n(Task, SalesOrder, GameAccount...)"]
            PORTS["Ports OUT\n(interfaces de repositório)"]
        end

        subgraph adapters_out["Adapter OUT — Persistence"]
            JPA["JPA Repositories\n(Spring Data)"]
            STORAGE["StorageAdapter\n(Local FS / S3)"]
        end
    end

    subgraph infra["Infraestrutura"]
        PG[("PostgreSQL 15")]
        S3["AWS S3\n(imagens de flow)"]
    end

    WEB -->|HTTP REST + JWT| CTRL
    BOT -->|HTTP REST + Device API Key| CTRL
    DEVICE -->|HTTP REST + JWT| CTRL
    CTRL --> SEC
    SEC --> SVC
    SVC --> MODEL
    SVC --> PORTS
    PORTS --> JPA
    PORTS --> STORAGE
    JPA --> PG
    STORAGE --> S3

    style core fill:#dbeafe,stroke:#3b82f6
    style domain fill:#ede9fe,stroke:#7c3aed
    style adapters_in fill:#d1fae5,stroke:#059669
    style adapters_out fill:#fef3c7,stroke:#d97706
```

---

## Arquitetura Hexagonal (Ports & Adapters)

```mermaid
graph LR
    subgraph left["Ports IN (driving)"]
        HTTP["HTTP Request\n(REST / Swagger)"]
    end

    subgraph hex["Core Hexagon"]
        direction TB
        CTRL2["Controller\n(Adapter IN)"]
        SVC2["Service\n(Use Case)"]
        DOM2["Domain Model\n(entity, value object)"]
        PORT_OUT["Port OUT\n(interface)"]
    end

    subgraph right["Ports OUT (driven)"]
        REPO["JPA Repository\n(Adapter OUT)"]
        STG["Storage Adapter\n(Local/S3)"]
        PG2[("PostgreSQL")]
        S3b["S3"]
    end

    HTTP --> CTRL2
    CTRL2 --> SVC2
    SVC2 --> DOM2
    SVC2 --> PORT_OUT
    PORT_OUT --> REPO
    PORT_OUT --> STG
    REPO --> PG2
    STG --> S3b

    style hex fill:#ede9fe,stroke:#7c3aed
```

### Pacotes Java

```
com.automation/
├── AutoUpgradeDdtApplication.java          # Entry point
├── bootstrap/
│   └── CoreApplicationBootstrap.java       # Inicialização / seeds
└── core/
    ├── adapter/
    │   ├── in/web/
    │   │   ├── controller/                  # REST Controllers (22 controllers)
    │   │   ├── dto/request/                 # Request DTOs por domínio
    │   │   ├── dto/response/                # Response DTOs
    │   │   └── security/                    # Filtros JWT + API Key
    │   └── out/
    │       ├── persistence/
    │       │   ├── entity/                  # JPA Entities
    │       │   ├── inter/                   # Spring Data JPA Repositories
    │       │   └── adapter/                 # PersistenceAdapters (implementam Ports OUT)
    │       └── storage/                     # StorageAdapter (local/S3)
    ├── application/
    │   ├── config/                          # Spring Beans, Security Config
    │   ├── exception/                       # Exceções de aplicação
    │   ├── input/                           # Ports IN (interfaces dos use cases)
    │   ├── output/                          # Ports OUT (interfaces de persistência)
    │   ├── service/                         # Implementações de use cases
    │   ├── startup/                         # Runners de seed/inicialização
    │   └── util/                            # Utilitários (crypto AES, JWT...)
    ├── domain/
    │   ├── model/                           # Entidades de domínio puras
    │   └── port/out/                        # Ports de saída do domínio
    └── security/                            # Configuração Spring Security
```

---

## Controllers e Endpoints

```mermaid
graph TD
    subgraph auth["Auth & Users"]
        A1["AuthController\nPOST /api/auth/login\nPOST /api/auth/refresh\nGET  /api/auth/me"]
        A2["UserAdminController\nGET/POST/PUT /api/users\nPOST /api/users/{id}/permissions"]
        A3["PermissionController\nGET/POST /api/permissions"]
    end

    subgraph catalog["Catálogo de Jogo"]
        C1["RangeServerController\nGET/POST /api/range-servers\nPOST /api/range-servers/batch"]
        C2["ServerController\nGET/POST /api/servers\nPOST /api/servers/batch"]
        C3["GameAccountController\nGET/POST/PUT /api/game-accounts\nPOST /api/game-accounts/batch"]
        C4["GameDetailsAccountController\nGET/POST/PUT /api/game-details-accounts"]
    end

    subgraph crm["CRM"]
        D1["CustomerController\nGET/POST/PUT/DELETE /api/customers"]
        D2["SalesOrderController\nGET/POST/PUT /api/sales-orders\nPOST /api/sales-orders/{id}/generate-tasks"]
        D3["WalletController\nGET/POST /api/wallet"]
    end

    subgraph tasks["Tasks & Workers"]
        E1["TaskController\nPOST /api/tasks/claim-next\nPATCH /api/tasks/{id}/status\nPATCH /api/tasks/{id}/account-level"]
        E2["DeviceController\nGET/POST/PUT /api/devices\nPOST /api/devices/provision"]
    end

    subgraph flows["Flows (Automação)"]
        F1["CollectionController\nGET/POST/PUT /api/collections"]
        F2["FlowController\nGET/POST/PUT /api/flows"]
        F3["FlowStepController\nGET/POST/PUT /api/flow-steps\nPOST /api/flow-steps/reorder"]
        F4["FlowStepImageController\nGET/POST/PUT/DELETE /api/flow-step-images"]
        F5["CollectionFlowController\nGET/POST /api/collection-flows"]
        F6["CollectionTransitionGraphController\nGET /api/collection-transition-graph"]
    end

    subgraph misc["Misc"]
        G1["AppReleaseController\nGET /api/app/release"]
        G2["NotificationController\nGET/PUT /api/notifications"]
        G3["HealthController\nGET /health"]
    end
```

---

## Fluxo de uma Task: do Pedido à Execução

```mermaid
sequenceDiagram
    participant W as Web CRM
    participant C as Core API
    participant PG as PostgreSQL
    participant BOT as Bot Android

    W->>C: POST /api/sales-orders (customer, range, order_type, accounts_count)
    C->>PG: INSERT sales_order (status=PENDING)
    W->>C: POST /api/sales-orders/{id}/generate-tasks
    C->>PG: SELECT game_accounts WHERE level < target LIMIT accounts_count
    C->>PG: SELECT servers WHERE range_server_id = range
    C->>PG: INSERT N tasks (sales_order, game_account, server_value, device_id, status=PENDING)
    C-->>W: tasks_total criadas

    loop Worker Loop
        BOT->>C: POST /api/tasks/claim-next {deviceApiKey, deviceIdentifier}
        C->>PG: SELECT task WHERE device_id=me AND status=PENDING LIMIT 1
        C->>PG: UPDATE task SET status=PROCESSING
        C-->>BOT: TaskWorkerPlanResponse (task + flow steps + templates Base64)
        BOT->>BOT: Executa automação (screenshot → Vision → click)
        BOT->>C: PATCH /api/tasks/{id}/status {status: FINISHED}
        C->>PG: UPDATE task SET status=FINISHED
        C->>PG: UPDATE sales_order SET tasks_completed += 1
        alt tasks_completed == tasks_total
            C->>PG: UPDATE sales_order SET status_order=FINISHED
            C->>PG: UPDATE customer.closed_purchases += 1
        end
    end
```

---

## Segurança

```mermaid
graph LR
    subgraph tokens["Mecanismos de Auth"]
        JWT["JWT (HS256)\nUsuários web/admin\nHeader: Authorization: Bearer"]
        APIKEY["Device API Key\nWorkers Android\nHeader: X-Device-Api-Key\nHash BCrypt no BD"]
    end

    subgraph crypto["Criptografia"]
        BCR["BCrypt\nSenhas de usuário admin\n(user_admin.password_hash)"]
        AES["AES-256-GCM\nSenhas de contas de jogo\n(game_account.password)\nпрефикс v1: em prod"]
    end

    subgraph roles["Roles (RBAC)"]
        ADM["ADM — acesso total"]
        DEV["DEV — debug/dev"]
        MGR["MANAGER — operações"]
        SLR["SELLER — pedidos/clientes"]
    end

    JWT --> ADM & DEV & MGR & SLR
    APIKEY -->|Somente workers| T["Tasks API\n(claim-next, status update)"]
```

---

## Tecnologias

| Camada | Tecnologia |
|--------|-----------|
| Linguagem | Java 17 |
| Framework | Spring Boot 3.x |
| Segurança | Spring Security + JWT + BCrypt |
| ORM | JPA / Hibernate (Spring Data JPA) |
| Database | PostgreSQL 15 |
| Storage | Local FS (dev) / AWS S3 (prod) |
| Build | Maven |
| API Docs | Swagger UI (`/swagger-ui/index.html`) |
| Deploy | Docker + AWS EC2 |

---

## Portas e Perfis

| Perfil | Porta | DB | Notas |
|--------|-------|----|-------|
| `local` | 8081 | automation_db | dev na máquina, ddl-auto=update |
| `dev` | 8080 | automation_db | docker, ddl-auto=validate |
| `prod` | 8080 | automation_db | EC2, ddl-auto=validate, HTTPS |
| `docker` | 8082 | postgres container | bootstrap.sh local completo |
