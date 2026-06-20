# Fluxo da Task (hexagonal)

## Desenho do fluxo

```mermaid
flowchart LR
    subgraph ADAPTER_IN["Adapter IN (Web)"]
        HTTP[HTTP Request]
        TC[TaskController]
        HTTP --> TC
    end

    subgraph PORT_IN["Port IN / Use Case"]
        TS[TaskService]
    end

    subgraph PORT_OUT["Port OUT (interface)"]
        TPP[TaskPersistencePort]
    end

    subgraph ADAPTER_OUT["Adapter OUT (Persistence)"]
        TPA[TaskPersistenceAdapter]
    end

    subgraph JPA["Infra"]
        TJPA[TaskJpaRepository]
        DB[(database)]
        TJPA --> DB
    end

    TC -->|"list(salesOrderId, statusTask)"| TS
    TC -->|"getById(id)"| TS
    TC -->|"updateStatus(id, request)"| TS

    TS -->|"findAll(), findById(), save()"| TPP
    TPP -.->|implementa| TPA
    TPA -->|delega| TJPA
```

## Fluxo em sequência (listar tarefas)

```mermaid
sequenceDiagram
    participant Cliente
    participant TaskController
    participant TaskService
    participant TaskPersistencePort
    participant TaskPersistenceAdapter
    participant TaskJpaRepository
    participant DB

    Cliente->>TaskController: GET /api/tasks?salesOrderId=1&statusTask=PENDING
    TaskController->>TaskService: list(1, "PENDING")
    TaskService->>TaskPersistencePort: findAll()
    TaskPersistencePort->>TaskPersistenceAdapter: findAll()
    TaskPersistenceAdapter->>TaskJpaRepository: findAll()
    TaskJpaRepository->>DB: SELECT * FROM task
    DB-->>TaskJpaRepository: rows
    TaskJpaRepository-->>TaskPersistenceAdapter: List<TaskEntity>
    TaskPersistenceAdapter-->>TaskService: List<TaskEntity>
    TaskService->>TaskService: filtra por salesOrderId e statusTask
    TaskService-->>TaskController: List<TaskEntity>
    TaskController->>TaskController: map toResponse() → TaskResponse
    TaskController-->>Cliente: 200 + JSON List<TaskResponse>
```

## Fluxo em sequência (atualizar status)

```mermaid
sequenceDiagram
    participant Cliente
    participant TaskController
    participant TaskService
    participant TaskPersistencePort
    participant TaskPersistenceAdapter
    participant TaskJpaRepository
    participant DB

    Cliente->>TaskController: PATCH /api/tasks/123/status {"statusTask": "DONE"}
    TaskController->>TaskService: updateStatus(123, request)
    TaskService->>TaskPersistencePort: findById(123)
    TaskPersistencePort->>TaskPersistenceAdapter: findById(123)
    TaskPersistenceAdapter->>TaskJpaRepository: findById(123)
    TaskJpaRepository->>DB: SELECT
    DB-->>TaskJpaRepository: TaskEntity
    TaskJpaRepository-->>TaskPersistenceAdapter: Optional<TaskEntity>
    TaskPersistenceAdapter-->>TaskService: Optional<TaskEntity>
    TaskService->>TaskService: e.setStatusTask("DONE"); save(e)
    TaskService->>TaskPersistencePort: save(e)
    TaskPersistencePort->>TaskPersistenceAdapter: save(e)
    TaskPersistenceAdapter->>TaskJpaRepository: save(e)
    TaskJpaRepository->>DB: UPDATE task
    TaskJpaRepository-->>TaskPersistenceAdapter: TaskEntity
    TaskPersistenceAdapter-->>TaskService: TaskEntity
    TaskService-->>TaskController: Optional<TaskEntity>
    TaskController->>TaskController: toResponse() → TaskResponse
    TaskController-->>Cliente: 200 + JSON TaskResponse
```

## Resumo em camadas

| Camada        | Componente              | Responsabilidade                                      |
|---------------|-------------------------|--------------------------------------------------------|
| **Adapter IN**  | TaskController          | Recebe HTTP, valida DTO, chama use case, devolve JSON. |
| **Port IN**     | TaskService (use case)  | Orquestra: filtros, atualização de status.            |
| **Port OUT**    | TaskPersistencePort     | Interface: findById, findAll, save, countBySalesOrderId. |
| **Adapter OUT** | TaskPersistenceAdapter  | Implementa a port; usa TaskJpaRepository.              |
| **Infra**       | TaskJpaRepository + DB  | Persistência JPA.                                     |

**Direção das dependências:** Controller → Service → Port (interface). O use case não conhece JPA; só a interface. O adapter implementa a interface e usa JPA.
