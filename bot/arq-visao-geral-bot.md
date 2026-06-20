# automation-bot-lab — Arquitetura

App Android Kotlin que funciona como **worker** da plataforma DDT. Executa automação de UI no dispositivo (click, swipe, input), integra com Vision API para reconhecimento de tela, e se comunica com o Core API para buscar e reportar tasks.

---

## Visão Macro

```mermaid
graph TB
    subgraph device["Dispositivo Android"]
        direction TB

        subgraph presentation["Presentation Layer"]
            MA["MainActivity\n(UI principal)"]
            LA["LoginActivity\n(auth Core)"]
            DSA["DeviceSettingsActivity\n(config device)"]
            VM["BotViewModel\n(estado reativo)"]
        end

        subgraph domain["Domain Layer"]
            ORCH["AutomationOrchestrator\n(loop infinito)"]
            START["StartBotUseCase"]
            STOP["StopBotUseCase"]
            NET["NetworkValidator"]
            LOGIN["FlowLoginUseCase"]
            MACRO["MacroRunner + FlowEffectRegistry\n(executor de planos JSON)"]
            SESSION["SessionEngine + GameSessionController"]
        end

        subgraph data["Data Layer"]
            VREPO["VisionRepositoryImpl"]
            SCREPO["ScreenshotRepositoryImpl"]
            CREPO["ClickRepositoryImpl"]
            CTREPO["CoreTaskRepositoryImpl"]
            MAPPER["VisionDtoMapper\nCoreTaskPlanMapper"]
            CACHE["WorkerFlowPlanCache"]
        end

        subgraph automation_layer["Automation (Android)"]
            CAPTURE["ScreenCapture\n(MediaProjection)"]
            CLICKER["ScreenClicker\n(AccessibilityService)"]
            LAUNCHER["AppLauncher"]
            ACC["BotAccessibilityService"]
        end

        subgraph di["DI"]
            FACTORY["BotFactory\n(montagem manual do grafo)"]
        end
    end

    subgraph external["Serviços externos"]
        VISION["Vision API\nFastAPI :8000"]
        CORE["Core API\nSpring Boot :8080"]
    end

    MA --> FACTORY
    FACTORY --> VM
    VM --> START & STOP
    START --> ORCH
    ORCH --> NET & LOGIN & MACRO & SESSION
    LOGIN --> VREPO & SCREPO & CREPO
    MACRO --> VREPO & SCREPO & CREPO
    CTREPO -->|claim-next / status update| CORE
    VREPO -->|lens / match / OCR| VISION
    SCREPO --> CAPTURE
    CREPO --> CLICKER
    CLICKER --> ACC

    style domain fill:#ede9fe,stroke:#7c3aed
    style data fill:#dbeafe,stroke:#3b82f6
    style automation_layer fill:#d1fae5,stroke:#059669
    style presentation fill:#fef3c7,stroke:#d97706
```

---

## BotFactory — Grafo de Dependências

O `BotFactory` é o único ponto de montagem (composição raiz). Recebe `Context`, `FloatingLogWindow` e `onMainLog`, e retorna apenas `BotViewModel`.

```mermaid
flowchart TB
    subgraph inputs["Entradas"]
        ctx[Context]
        floating[FloatingLogWindow]
        onMainLog["onMainLog callback"]
    end

    subgraph logging["Logging"]
        logMgr[LogFileManager]
        botLogTree[BotLogTree]
    end

    subgraph api_layer["API (DTO)"]
        visionApi[VisionApiService]
        coreApi[CoreApiService / CoreAuthApi]
    end

    subgraph data_layer["Data (Repository + Mapper)"]
        visionRepo[VisionRepositoryImpl]
        screenshotRepo[ScreenshotRepositoryImpl]
        clickRepo[ClickRepositoryImpl]
        coreTaskRepo[CoreTaskRepositoryImpl]
        visionMapper[VisionDtoMapper]
        planMapper[CoreTaskPlanMapper]
    end

    subgraph domain_layer["Domain"]
        netValidator[NetworkValidator]
        screenValidator[ScreenValidator / ScreenToolkit]
        detectClick[DetectAndClickUseCase]
        flowLogin[FlowLoginUseCase]
        macroRunner[MacroRunner + FlowEffectRegistry]
        orchestrator[AutomationOrchestrator]
        startUC[StartBotUseCase]
        stopUC[StopBotUseCase]
    end

    subgraph output["Saída"]
        vm[BotViewModel]
    end

    ctx --> logMgr & visionApi & screenshotRepo & clickRepo & netValidator & coreApi
    floating --> logMgr
    logMgr --> botLogTree
    visionApi --> visionRepo
    coreApi --> coreTaskRepo
    visionRepo --> visionMapper
    visionRepo --> screenValidator
    screenshotRepo --> screenValidator
    clickRepo --> detectClick
    screenValidator --> detectClick & flowLogin & orchestrator
    detectClick --> flowLogin & macroRunner
    screenshotRepo --> flowLogin & macroRunner
    visionRepo --> flowLogin & macroRunner
    coreTaskRepo --> orchestrator
    macroRunner --> orchestrator
    netValidator --> orchestrator & startUC
    flowLogin --> orchestrator
    orchestrator --> startUC
    startUC & stopUC & floating & logMgr --> vm
```

---

## Orchestrator — Loop Infinito

```mermaid
flowchart TD
    START([Bot Start]) --> VALIDATE_NET

    VALIDATE_NET{"Rede OK?\n(NetworkValidator)"}
    VALIDATE_NET -->|Falha| STOP_BOT([Stop Bot])
    VALIDATE_NET -->|OK| CLAIM_TASK

    CLAIM_TASK["POST /api/tasks/claim-next\n(CoreTaskRepository)"]
    CLAIM_TASK -->|204 sem task| IDLE["delay 10s → repete"]
    IDLE --> VALIDATE_NET
    CLAIM_TASK -->|200 TaskWorkerPlanResponse| BUILD_PLAN

    BUILD_PLAN["CoreTaskPlanMapper\nconstrói TaskWorkerPlan\n(steps + imagens Base64)"]
    BUILD_PLAN --> EXEC_FLOW

    EXEC_FLOW["MacroRunner executa plano\nloop: step → step_img → Vision → click"]

    subgraph loop_steps["Loop por step (step_number ASC)"]
        EXEC_FLOW --> NEXT_STEP{Próximo step?}
        NEXT_STEP -->|sim| NEXT_IMG
        NEXT_IMG{Próxima imagem?}
        NEXT_IMG -->|sim| RUN_ACTION["Executar ação\n(CLICK / WAIT_APPEAR /\nIF_VISIBLE / OCR / GOTO...)"]
        RUN_ACTION --> ACTION_OK{Sucesso?}
        ACTION_OK -->|sim| NEXT_IMG
        ACTION_OK -->|não| RETRY["retry / ERROR"]
        RETRY --> REPORT_ERR["PATCH /api/tasks/{id}/status\nERROR"]
        NEXT_IMG -->|fim| NEXT_STEP
        NEXT_STEP -->|fim| REPORT_OK
    end

    REPORT_OK["PATCH /api/tasks/{id}/status\nFINISHED"]
    REPORT_OK --> VALIDATE_NET
    REPORT_ERR --> VALIDATE_NET
```

---

## Integração Vision API

```mermaid
sequenceDiagram
    participant Orch as MacroRunner
    participant VRepo as VisionRepositoryImpl
    participant Mapper as VisionDtoMapper
    participant VApi as VisionApiService
    participant Vision as Vision API :8000

    Orch->>VRepo: detectElement(templateBitmap, screenshot, threshold)
    VRepo->>VApi: POST /api/v1/vision/lens (template Base64, screenshot Base64)
    VApi->>Vision: HTTP POST
    Vision-->>VApi: LensResponse (DTO: found, x, y, w, h, confidence)
    VApi-->>VRepo: LensResponse (DTO)
    VRepo->>Mapper: toScreenMatch(dto, threshold)
    Mapper-->>VRepo: ScreenMatch (entity: isMatch, centerX, centerY)
    VRepo-->>Orch: ScreenMatch

    alt isMatch == true
        Orch->>ClickRepo: clickAt(centerX, centerY)
        ClickRepo->>BotAccessibility: dispatchGesture(x, y)
    end
```

---

## Camadas e Responsabilidades

```mermaid
mindmap
  root((Bot DDT))
    Presentation
      MainActivity UI principal
      LoginActivity autenticação Core
      DeviceSettingsActivity config
      BotViewModel estado reativo LiveData
    Domain
      AutomationOrchestrator loop principal
      MacroRunner executa plano de steps
      FlowEffectRegistry CLICK WAIT GOTO OCR
      FlowLoginUseCase fluxo de login local
      NetworkValidator valida rede e Vision health
      SessionEngine controla sessão de jogo
    Data
      VisionRepositoryImpl chama Vision API
      CoreTaskRepositoryImpl chama Core API
      ScreenshotRepositoryImpl captura tela
      ClickRepositoryImpl gestos de toque
      VisionDtoMapper DTO para Entity
      CoreTaskPlanMapper DTO para TaskWorkerPlan
    Automation Android
      BotAccessibilityService Accessibility API
      MediaProjectionCapture captura de tela via MediaProjection
      ScreenCapture abstração de captura
      ScreenClicker dispara gestos
      AppLauncher abre fecha app
    DI
      BotFactory montagem manual do grafo
```

---

## Fluxo de Autenticação do Worker

```mermaid
sequenceDiagram
    participant LA as LoginActivity
    participant CoreAuth as CoreAuthApi
    participant Core as Core API
    participant Store as CoreSessionStore

    LA->>CoreAuth: POST /api/auth/login {login, password}
    Core-->>CoreAuth: {token, refreshToken, profile}
    CoreAuth-->>LA: LoginResponseDto
    LA->>Store: salva token + deviceId (SharedPreferences encriptado)
    Note over Store: CoreSessionStoreImpl persiste localmente

    Note over LA: A cada request subsequente:
    LA->>CoreAuth: GET /api/auth/me (Bearer token)
    Core-->>CoreAuth: {id, login, name, role}
```

---

## Permissões Android

| Permissão | Uso |
|-----------|-----|
| `INTERNET` | Comunicação com Core API e Vision API |
| `FOREGROUND_SERVICE` | Manter bot ativo em background |
| `MEDIA_PROJECTION` | Captura de tela (screenshots) |
| `ACCESSIBILITY_SERVICE` | Gestos de toque via `BotAccessibilityService` |
| `SYSTEM_ALERT_WINDOW` | Overlay de logs flutuante |
| `RECEIVE_BOOT_COMPLETED` | Auto-start opcional |

---

## Tecnologias

| Item | Tecnologia |
|------|-----------|
| Linguagem | Kotlin |
| SDK mínimo | Android 26 (Oreo) |
| HTTP | Retrofit 2 + OkHttp |
| Async | Kotlin Coroutines + Flow |
| DI | Manual (BotFactory) |
| Logging | Timber + LogFileManager |
| Build | Gradle (Kotlin DSL) |
| Testes | JUnit 4 + MockK |
