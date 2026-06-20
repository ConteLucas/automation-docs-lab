# [ERROR] COMPILATION ERROR : 

[INFO] -------------------------------------------------------------

[ERROR] /Users/experiment/Developer/git/automation-learn/automation-core-lab/src/main/java/com/automation/core/application/service/[WorkerFlowSyncService.java](http://WorkerFlowSyncService.java):[128,32] normalizeKey(java.lang.String) is not public in [com.automation.core.adapter.out.storage](http://com.automation.core.adapter.out.storage).S3PresignService; cannot be accessed from outside package

[INFO] 1 error

[INFO] -------------------------------------------------------------

[INFO] ------------------------------------------------------------------------

[INFO] BUILD FAILURE

[INFO] ------------------------------------------------------------------------

[INFO] Total time:  3.167 s

[INFO] Finished at: 2026-06-20T19:07:55-03:00

[INFO] ------------------------------------------------------------------------

[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.11.0:compile (default-compile) on project automation-core-ddt: Compilation failure

[ERROR] /Users/experiment/Developer/git/automation-learn/automation-core-lab/src/main/java/com/automation/core/application/service/[WorkerFlowSyncService.java](http://WorkerFlowSyncService.java):[128,32] normalizeKey(java.lang.String) is not public in [com.automation.core.adapter.out.storage](http://com.automation.core.adapter.out.storage).S3PresignService; cannot be accessed from outside package

[ERROR] 

[ERROR] -> [Help 1]

[ERROR] 

[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.

[ERROR] Re-run Maven using the -X switch to enable full debug logging.

[ERROR] 

[ERROR] For more information about the errors and possible solutions, please read the following articles:

[ERROR] [Help 1] [http://cwiki.apache.org/confluence/display/MAVEN/MojoFailureException](http://cwiki.apache.org/confluence/display/MAVEN/MojoFailureException)

[deploy] mvn package falhou.

[deploy] Use JDK 17 ou 21 — nao JDK 25: export JAVA_HOME=$(/usr/libexec/java_home -v 21)Plataforma DDT — Arquitetura do Ecossistema

Visão arquitetural completa do monorepo **automation-learn**: uma plataforma de automação de game bots que orquestra pedidos de clientes, delega tarefas a dispositivos Android, executa automação de UI com visão computacional e oferece um painel web de administração.

---

## Visão Macro — Social Graph do Ecossistema

```mermaid
graph TB
    subgraph external["Atores Externos"]
        ADMIN["Administrador\n(operador)"]
        SELLER["Vendedor / Cliente"]
        ANDROID_DEV["Desenvolvedor Android\n(device lab)"]
    end

    subgraph platform["Plataforma DDT — automation-learn"]
        WEB["automation-web-lab\nReact CRM\n:5175 / :80"]
        CORE["automation-core-lab\nSpring Boot API\n:8080 / :8081"]
        VISION["automation-vision-lab\nFastAPI OCR\n:8000"]
        BOT["automation-bot-lab\nAndroid Worker\nAPK"]
        DEVICE["automation-device-lab\nDesktop Tool\n(local)"]
        DB["automation-db-lab\nPostgreSQL Schema\n(referência)"]
        INFRA["automation-infra-lab\nTerraform + Docker\n(AWS EC2)"]
    end

    subgraph infra_aws["AWS"]
        EC2["EC2 t4g.micro"]
        S3["S3 (templates PNG)"]
        PG_DB[("PostgreSQL 15")]
    end

    ADMIN -->|CRM: pedidos, flows, devices| WEB
    SELLER -->|CRM: pedidos| WEB
    ANDROID_DEV -->|emparelha devices| DEVICE

    WEB -->|REST + JWT| CORE
    BOT -->|claim-next + status update\nDevice API Key| CORE
    DEVICE -->|provisiona device\nJWT admin| CORE
    BOT -->|lens / match / OCR\nVision API Key| VISION
    CORE -->|IAM role| S3
    CORE --> PG_DB

    INFRA -->|provisiona| EC2
    EC2 -->|roda docker-compose| CORE & WEB & VISION
    EC2 --- PG_DB

    DB -.->|DDL referência + seeds| CORE

    style WEB fill:#fef3c7,stroke:#d97706
    style CORE fill:#dbeafe,stroke:#3b82f6
    style VISION fill:#d1fae5,stroke:#059669
    style BOT fill:#ede9fe,stroke:#7c3aed
    style DEVICE fill:#fce7f3,stroke:#db2777
    style DB fill:#f3f4f6,stroke:#9ca3af
    style INFRA fill:#fef3c7,stroke:#d97706
```



---

## Fluxo Principal de Ponta a Ponta

```mermaid
sequenceDiagram
    actor OP as Operador
    participant WEB as Web CRM
    participant CORE as Core API
    participant PG as PostgreSQL
    participant BOT as Bot Android
    participant VISION as Vision API

    Note over OP,VISION: 1. CRIAÇÃO DO PEDIDO
    OP->>WEB: Cria pedido (cliente, range, tipo ACC30, 30 contas)
    WEB->>CORE: POST /api/sales-orders
    CORE->>PG: INSERT sales_order (status=PENDING)
    OP->>WEB: Gera tasks
    WEB->>CORE: POST /api/sales-orders/{id}/generate-tasks
    CORE->>PG: SELECT 30 game_accounts (level < 30)
    CORE->>PG: SELECT servers (range_1 = 8 servidores)
    CORE->>PG: INSERT 240 tasks (30 contas × 8 servers, mesmo device)
    CORE-->>WEB: tasks_total=240

    Note over OP,VISION: 2. EXECUÇÃO DAS TASKS (loop do bot)
    loop Cada task (240 iterações)
        BOT->>CORE: POST /api/tasks/claim-next {deviceId, apiKey}
        CORE->>PG: UPDATE task SET status=PROCESSING
        CORE-->>BOT: TaskWorkerPlanResponse\n(flow_steps + images Base64)

        loop Cada step do flow
            loop Cada imagem do step
                BOT->>VISION: POST /api/v1/vision/lens\n{template, screenshot, threshold}
                VISION-->>BOT: {found, x, y, confidence}
                alt found = true
                    BOT->>BOT: AccessibilityService.clickAt(x, y)
                end
            end
        end

        BOT->>CORE: PATCH /api/tasks/{id}/status FINISHED
        CORE->>PG: UPDATE task SET status=FINISHED
        CORE->>PG: UPDATE sales_order.tasks_completed += 1
    end

    Note over OP,VISION: 3. CONCLUSÃO
    CORE->>PG: UPDATE sales_order SET status=FINISHED
    CORE->>PG: UPDATE customer.closed_purchases += 1
    WEB-->>OP: Pedido 240/240 ✅
```



---

## Dependências Entre Sistemas

```mermaid
graph LR
    subgraph runtime["Runtime (sempre online)"]
        CORE_R["Core API"]
        VISION_R["Vision API"]
        PG_R[("PostgreSQL")]
        S3_R["S3 / Local Storage"]
    end

    subgraph workers["Workers (Android)"]
        BOT_R["Bot Android\n(1..N devices)"]
    end

    subgraph frontend["Frontend"]
        WEB_R["Web CRM\n(navegador)"]
    end

    subgraph local_tools["Ferramentas Locais"]
        DEVICE_R["Device Lab\n(desktop, opcional)"]
    end

    WEB_R -->|"HTTP REST (JWT)"| CORE_R
    BOT_R -->|"HTTP REST (API Key)"| CORE_R
    BOT_R -->|"HTTP REST (Vision Key)"| VISION_R
    DEVICE_R -->|"HTTP REST (JWT admin)"| CORE_R
    CORE_R --> PG_R
    CORE_R --> S3_R

    CORE_R -.->|"health check"| VISION_R
```



---

## Arquitetura por Camadas

```mermaid
graph TB
    subgraph layer1["Camada de Apresentação"]
        WEB_L["Web CRM\nReact + TypeScript + Vite\n@xyflow/react (diagramas)"]
        BOT_UI["Bot UI\nAndroid Activities + ViewModel\nLiveData / Coroutines"]
        DL_UI["Device Lab UI\nJava Desktop (JavaFX/Swing)"]
    end

    subgraph layer2["Camada de API / Orquestração"]
        CORE_L["Core API\nSpring Boot 3 + Hexagonal Architecture\nJWT + BCrypt + AES-256-GCM"]
    end

    subgraph layer3["Camada de Serviços Especializados"]
        VISION_L["Vision Service\nFastAPI + OpenCV + Tesseract\nTemplate Matching + OCR"]
    end

    subgraph layer4["Camada de Dados"]
        PG_L[("PostgreSQL 15\nJPA/Hibernate (ddl-auto)\n15 tabelas principais")]
        S3_L["AWS S3 / Local FS\nPNGs de flow templates"]
    end

    subgraph layer5["Camada de Infraestrutura"]
        DOCKER_L["Docker Compose\n4 serviços (web, core, vision, postgres)"]
        TF_L["Terraform\nEC2 + S3 + IAM + SG\n~US$9/mês após free tier"]
    end

    layer1 -->|REST HTTP| layer2
    layer1 -->|REST HTTP| layer3
    layer2 --> layer4
    layer5 -->|provisiona| layer2 & layer3 & layer4
```



---

## Mapa de Repositórios

```mermaid
mindmap
  root((automation-learn))
    automation-core-lab
      Spring Boot 3 Java 17
      Hexagonal Architecture
      22 Controllers REST
      JWT + BCrypt + AES
      JPA PostgreSQL
    automation-bot-lab
      Android Kotlin
      BotFactory DI manual
      AutomationOrchestrator loop
      MacroRunner executor de planos
      AccessibilityService gestos
      MediaProjection screenshots
    automation-vision-lab
      Python FastAPI
      OpenCV template matching
      Tesseract OCR
      endpoints lens match ocr
    automation-web-lab
      React 18 TypeScript
      Vite + Tailwind
      xyflow diagramas de flow
      14 páginas CRM
      AuthContext JWT
    automation-infra-lab
      Terraform AWS
      EC2 t4g.micro free tier
      S3 templates PNG
      Docker Compose prod
    automation-db-lab
      PostgreSQL 15 referência
      DDL e migrations históricas
      Seeds permission-seed.json
      15 tabelas + RBAC
    automation-device-lab
      Java Desktop App
      AVD Manager emuladores
      Device provisioning
      Instalador Windows exe
    automation-configs-lab
      docker-compose.yml monorepo
      bootstrap.sh dev local
      Documentação centralizada
      Templates de imagem
```



---

## Segurança — Visão Consolidada

```mermaid
graph TB
    subgraph boundaries["Fronteiras de Segurança"]
        INTERNET["Internet"]
        EC2_SG["EC2 Security Group\n:22 SSH (CIDR restrito)\n:80 HTTP (0.0.0.0)\n:8000 Vision (0.0.0.0)\nPostgres NÃO exposto"]
    end

    subgraph auth_mechanisms["Mecanismos de Autenticação"]
        JWT["JWT HS256\nusuários web/admin"]
        DEVICE_KEY["Device API Key\nworkers Android\nhash BCrypt no BD"]
        VISION_KEY["X-Vision-Api-Key\nbot → Vision API\nem prod obrigatório"]
        SSH["SSH Key pair\ndevops → EC2"]
        IAM["IAM Role\nEC2 → S3\nsem access key exposto"]
    end

    subgraph crypto["Criptografia em Repouso"]
        BCRYPT["BCrypt ($2a$)\nsenhas de user_admin\nAPI keys de device"]
        AES256["AES-256-GCM (v1:)\nsenhas de game_account\nem produção"]
    end

    subgraph rbac["RBAC"]
        ADM_R["ADM — acesso total"]
        DEV_R["DEV — debug + config"]
        MGR_R["MANAGER — operações"]
        SLR_R["SELLER — pedidos + clientes"]
    end

    INTERNET --> EC2_SG
    EC2_SG --> JWT & DEVICE_KEY & VISION_KEY
    JWT --> ADM_R & DEV_R & MGR_R & SLR_R
    DEVICE_KEY --> BCRYPT
```



---

## Tecnologias por Repositório


| Repo                    | Linguagem    | Framework           | Deploy                   |
| ----------------------- | ------------ | ------------------- | ------------------------ |
| `automation-core-lab`   | Java 17      | Spring Boot 3 + JPA | Docker EC2 / local       |
| `automation-bot-lab`    | Kotlin       | Android SDK 26+     | APK (sideload/emulador)  |
| `automation-vision-lab` | Python 3.10+ | FastAPI + OpenCV    | Docker EC2 / local       |
| `automation-web-lab`    | TypeScript   | React 18 + Vite     | Docker Nginx EC2 / local |
| `automation-infra-lab`  | HCL          | Terraform           | AWS CLI                  |
| `automation-db-lab`     | SQL          | PostgreSQL 15       | gerenciado pelo Core     |
| `automation-device-lab` | Java 17      | JavaFX/Swing        | Executável (.exe / .dmg) |


---

## Ambiente de Desenvolvimento Local

```mermaid
graph LR
    subgraph dev["Desenvolvimento (bootstrap.sh)"]
        COMPOSE_DEV["docker-compose.yml\n(automation-configs-lab)"]
        WEB_DEV["app-web :5175\n(Vite HMR)"]
        CORE_DEV["automation-core :8082\n(Spring Boot docker)"]
        VISION_DEV["automation-vision :8000\n(FastAPI)"]
        PG_DEV[("postgres :5432")]
        S3_LOCAL["Local FS\n(no S3 em dev)"]
    end

    COMPOSE_DEV --> WEB_DEV & CORE_DEV & VISION_DEV & PG_DEV
    CORE_DEV --> PG_DEV & S3_LOCAL

    subgraph dev_extras["Extras de Dev"]
        SWAGGER["Swagger UI\nlocalhost:8082/swagger-ui"]
        SEEDS["Seeds automáticos\npermission + massa.sql"]
        USERS["Usuários dev\nadmin/admin dev/dev\nmanager/manager seller/seller"]
        TEST_DEVICE["Device teste\ndevice-android-001\napi-key: dev-device-key-001"]
    end
```



### Comandos de início rápido

```bash
# Stack completa (recomendado)
./automation-configs-lab/bootstrap.sh

# Core no host (porta 8081, perfil local)
cd automation-core-lab && SPRING_PROFILES_ACTIVE=local mvn spring-boot:run

# Web em dev (proxy Vite → Core)
cd automation-web-lab && npm install && npm run dev

# Vision apenas
cd automation-vision-lab && docker compose up -d --build vision
```


| Serviço    | URL                                                                                        |
| ---------- | ------------------------------------------------------------------------------------------ |
| Web CRM    | [http://localhost:5175](http://localhost:5175)                                             |
| Core API   | [http://localhost:8082/api](http://localhost:8082/api)                                     |
| Swagger    | [http://localhost:8082/swagger-ui/index.html](http://localhost:8082/swagger-ui/index.html) |
| Vision OCR | [http://localhost:8000](http://localhost:8000)                                             |


---

## Relacionamento de Dados — Chave de Leitura

```mermaid
graph LR
    subgraph order_lifecycle["Ciclo de Vida de um Pedido"]
        CUST_N["customer\n(quem pediu)"]
        SO_N["sales_order\n(o pedido)"]
        TSK_N["task × N\n(1 por conta × servidor)"]
        GA_N["game_account\n(credenciais)"]
        SRV_N["server\n(s1..s65)"]
        DEV_N["device\n(bot Android)"]
        FS_N["flow_step\n(etapa do fluxo)"]
        FSI_N["flow_step_image\n(template OCR)"]
        DI_N["debug_image\n(screenshot de erro)"]
        OTL_N["order_task_log\n(erro crítico)"]
    end

    CUST_N -->|1:N| SO_N
    SO_N -->|1:N| TSK_N
    GA_N -->|1:N| TSK_N
    SRV_N -->|server_value| TSK_N
    DEV_N -->|1 device p/ todos| TSK_N
    FS_N -->|etapa atual| TSK_N
    FS_N -->|1:N| FSI_N
    TSK_N -->|1:N| DI_N
    TSK_N -->|1:N| OTL_N
```



---

## Documentação por Repositório


| Repo                           | Documento                                                                                                                                         |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `automation-core-lab/docs/`    | [ARCHITECTURE.md](automation-core-lab/docs/ARCHITECTURE.md)                                                                                       |
| `automation-bot-lab/docs/`     | [ARCHITECTURE.md](automation-bot-lab/docs/ARCHITECTURE.md)                                                                                        |
| `automation-vision-lab/docs/`  | [ARCHITECTURE.md](automation-vision-lab/docs/ARCHITECTURE.md)                                                                                     |
| `automation-web-lab/docs/`     | [ARCHITECTURE.md](automation-web-lab/docs/ARCHITECTURE.md)                                                                                        |
| `automation-infra-lab/docs/`   | [ARCHITECTURE.md](automation-infra-lab/docs/ARCHITECTURE.md)                                                                                      |
| `automation-db-lab/docs/`      | [ARCHITECTURE.md](automation-db-lab/docs/ARCHITECTURE.md)                                                                                         |
| `automation-device-lab/docs/`  | [ARCHITECTURE.md](automation-device-lab/docs/ARCHITECTURE.md)                                                                                     |
| `automation-configs-lab/docs/` | [REPOSITORIES-OVERVIEW.md](automation-configs-lab/docs/REPOSITORIES-OVERVIEW.md) · [TECH-STORIES.md](automation-configs-lab/docs/TECH-STORIES.md) |
| **Legados**                    | [LEGACY.md](LEGACY.md)                                                                                                                            |


