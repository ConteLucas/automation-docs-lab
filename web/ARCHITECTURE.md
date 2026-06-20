# automation-web-lab — Arquitetura

Dashboard CRM React para administração da plataforma DDT. Interface para criar pedidos de venda, gerenciar fluxos de automação, monitorar devices/workers, controlar contas de jogo e acompanhar execução de tasks em tempo real.

---

## Visão Macro

```mermaid
graph TB
    subgraph browser["Browser (React SPA)"]
        direction TB

        subgraph contexts["Contextos Globais"]
            AUTH["AuthContext\n(JWT token, user, role)"]
            THEME["ThemeContext\n(light/dark)"]
        end

        subgraph pages["Páginas"]
            LOGIN["Login\n/login"]
            DASH["Dashboard\n/"]
            ORDERS["Pedidos\n/orders"]
            NEW_ORDER["Novo Pedido\n/orders/new"]
            TASKS["Tasks\n/tasks"]
            FLOWS["Flows\n/flow"]
            FLOW_IMG["Imagens do Step\n/flow/:stepId/imagens"]
            ACCOUNTS["Contas\n/accounts"]
            CUSTOMERS["Clientes\n/customers"]
            DEVICES["Devices\n/devices"]
            USERS["Usuários\n/admin/users"]
            WALLET["Carteira\n/wallet"]
            NOTIF["Notificações\n/notifications"]
            DOWNLOADS["Downloads\n/downloads"]
            SETTINGS["Configurações\n/settings"]
        end

        subgraph components["Componentes Especiais"]
            SHELL["AppShell (layout)"]
            FLOW_CANVAS["FlowDiagramCanvas\n(@xyflow/react)"]
            COLL_CANVAS["CollectionDiagramCanvas\n(grafo de transições)"]
            ADMIN_ROUTE["AdminRoute / RoleRoute\n(guardas de rota)"]
            GENERATE_MODAL["GenerateTasksFromOrderModal"]
        end
    end

    subgraph backend["Backend"]
        CORE["Core API\nSpring Boot :8080"]
    end

    AUTH -->|Bearer token| CORE
    pages --> CORE
    FLOW_CANVAS -->|flow steps + images| CORE
    COLL_CANVAS -->|collection graph| CORE

    style browser fill:#fef3c7,stroke:#d97706
    style contexts fill:#ede9fe,stroke:#7c3aed
    style pages fill:#dbeafe,stroke:#3b82f6
```

---

## Roteamento e Proteção

```mermaid
graph TD
    ROOT["/"] --> SHELL["AppShell"]
    SHELL --> AUTH_CHECK{Autenticado?}
    AUTH_CHECK -->|não| REDIR["redirect /login"]
    AUTH_CHECK -->|sim| ROLE_CHECK{Tem role?}

    ROLE_CHECK -->|ADM/DEV/MANAGER/SELLER| PUBLIC_ROUTES
    ROLE_CHECK -->|somente ADM/DEV| ADMIN_ROUTES

    subgraph PUBLIC_ROUTES["Rotas autenticadas"]
        R1["/ → DashboardHome"]
        R2["/orders → SalesOrderList"]
        R3["/orders/new → NewOrder"]
        R4["/tasks → Tasks"]
        R5["/accounts → Accounts"]
        R6["/customers → Customers"]
        R7["/devices → Devices"]
        R8["/flow → FlowManagement"]
        R9["/flow/:stepId/imagens → FlowStepImages"]
        R10["/wallet → Wallet"]
        R11["/notifications → Notifications"]
        R12["/downloads → Downloads"]
        R13["/settings → Settings"]
    end

    subgraph ADMIN_ROUTES["Rotas admin (ADM/DEV)"]
        A1["/admin/users → AdminUsers"]
    end
```

---

## Fluxo de Autenticação

```mermaid
sequenceDiagram
    participant U as Usuário
    participant LP as LoginPage
    participant AC as AuthContext
    participant API as Core API

    U->>LP: POST {login, password}
    LP->>API: POST /api/auth/login
    API-->>LP: {token, refreshToken, name, role}
    LP->>AC: setUser({token, name, role})
    AC->>AC: localStorage.setItem(token)
    LP-->>U: redirect /

    Note over AC: Em toda requisição:
    AC->>API: Authorization: Bearer {token}

    Note over AC: Refresh automático (401):
    AC->>API: POST /api/auth/refresh {refreshToken}
    API-->>AC: {token, refreshToken}
    AC->>AC: atualiza localStorage
```

---

## Módulo de Flows (Automação)

```mermaid
graph TB
    subgraph flow_module["Módulo de Flows — /flow"]
        direction TB

        subgraph data["Dados carregados no mount (loadAll)"]
            COLL["Collections\nGET /api/collections"]
            FLOWS_D["Flows\nGET /api/flows"]
            STEPS["Flow Steps\nGET /api/flow-steps"]
            IMGS["Flow Step Images\nGET /api/flow-step-images"]
        end

        subgraph views["Modos de visualização"]
            LIST_VIEW["Modo Lista\n(tabela de imagens)"]
            DIAGRAM_VIEW["Modo Diagrama\n(cards + chips por step)"]
            FLOW_CANVAS2["FlowDiagramCanvas\n(@xyflow/react)\nnós = steps\narestas = ordem"]
            COLL_DIAG["CollectionDiagramCanvas\n(grafo dagre de transições)"]
        end

        subgraph images_page["Página de Imagens /flow/:stepId/imagens"]
            IMG_TABLE["Tabela completa de imagens"]
            IMG_DIAG["Diagrama com previews"]
            DND["Drag-and-Drop (reorder step_img_number)"]
            UPLOAD["Upload de PNG → Core → S3/local"]
            EFFECT["FlowStepEffectEditor\n(ação: CLICK, WAIT_APPEAR,\nGOTO, IF_VISIBLE, OCR...)"]
        end
    end

    COLL & FLOWS_D & STEPS & IMGS --> LIST_VIEW & DIAGRAM_VIEW & FLOW_CANVAS2 & COLL_DIAG
    IMGS --> IMG_TABLE & IMG_DIAG & DND
    UPLOAD -->|POST /api/flow-step-images| IMG_TABLE
    EFFECT -->|PUT /api/flow-step-images/{id}| IMG_TABLE
```

---

## Criação de Pedido e Geração de Tasks

```mermaid
sequenceDiagram
    participant U as Usuário
    participant NOP as NewOrder Page
    participant API as Core API

    U->>NOP: Preenche form (cliente, range, tipo, qtd contas)
    NOP->>API: POST /api/sales-orders
    API-->>NOP: {id, status: PENDING, tasks_total: 0}

    U->>NOP: Clica "Gerar Tasks"
    NOP->>API: POST /api/sales-orders/{id}/generate-tasks
    Note over API: Core valida contas disponíveis\nescolhe device\ncria N tasks
    API-->>NOP: {tasks_total: 240, status: PENDING}

    NOP-->>U: redirect /tasks?orderId={id}
```

---

## Componentes de UI Notáveis

```mermaid
graph LR
    subgraph visual["Componentes Visuais"]
        FC["FlowDiagramCanvas\n@xyflow/react\nnós interativos\narrasttáveis"]
        CC["CollectionDiagramCanvas\ngrafos com dagre\n(layout automático)"]
        PC["PriorityCircle\ncírculo de prioridade\n(CRITICAL/HIGH/NORMAL/LOW)"]
        WAP["WorkerActionPicker\nseletor de ações\ndo bot (effect type)"]
        FSEE["FlowStepEffectEditor\nconfigurador de efeito\npor imagem"]
        GTIP["GotoTargetImagePreview\npreview de destino GOTO"]
        DLDD["DeviceLabDesktopDownloads\ndownload do instalador"]
        CEO["ClickEffectOverlay\noverlay visual de click"]
    end
```

---

## Estrutura de Arquivos

```
automation-web-lab/
├── src/
│   ├── main.tsx             # Entry point React
│   ├── App.tsx              # Router + providers
│   ├── context/
│   │   ├── AuthContext.tsx  # Auth global (JWT, role, login/logout)
│   │   └── ThemeContext.tsx # Tema dark/light
│   ├── components/          # 15+ componentes reutilizáveis
│   │   ├── AppShell.tsx     # Layout principal (nav, sidebar)
│   │   ├── FlowDiagramCanvas.tsx      # Diagrama @xyflow
│   │   ├── CollectionDiagramCanvas.tsx # Grafo dagre
│   │   ├── AdminRoute.tsx   # Guarda de rota admin
│   │   └── ...
│   └── pages/               # 14 páginas
│       ├── DashboardHome/   # Dashboard /
│       ├── SalesOrderList/  # Pedidos /orders
│       ├── NewOrder/        # Novo pedido /orders/new
│       ├── Tasks/           # Tasks /tasks
│       ├── FlowManagement/  # Flows /flow
│       ├── FlowStepImages/  # Imagens /flow/:id/imagens
│       ├── Accounts/        # Contas /accounts
│       ├── Customers/       # Clientes /customers
│       ├── Devices/         # Devices /devices
│       ├── AdminUsers/      # Usuários /admin/users
│       ├── Wallet/          # Carteira /wallet
│       ├── Notifications/   # Notificações /notifications
│       ├── Downloads/       # Downloads /downloads
│       └── Settings/        # Configurações /settings
├── public/                  # Assets estáticos
├── dist/                    # Build (nginx serve)
├── index.html               # Template HTML
├── vite.config.ts           # Build config (proxy /api → Core)
├── nginx.conf.template      # Nginx prod (serve SPA + proxy)
└── Dockerfile               # Build + nginx
```

---

## Tecnologias

| Item | Tecnologia |
|------|-----------|
| Linguagem | TypeScript |
| Framework | React 18 |
| Build | Vite |
| Roteamento | React Router DOM v6 |
| Diagrama de Flows | @xyflow/react v12 + dagre |
| Ícones | lucide-react |
| CSS | Tailwind CSS |
| Deploy | Docker + Nginx (serve SPA + proxy `/api`) |
| Porta prod | 80 (Nginx) / 5175 (dev Vite) |

---

## Proxy de API (Vite dev / Nginx prod)

**Dev** (`vite.config.ts`): `/api` → `http://localhost:8082` (Core no docker)

**Prod** (`nginx.conf`):
```nginx
location /api {
    proxy_pass http://core:8081;
}
location / {
    try_files $uri $uri/ /index.html;
}
```
