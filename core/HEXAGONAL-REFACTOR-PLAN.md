# Plano para alinhar o Core ao Hexagonal

Objetivo: tirar a lógica e as dependências dos controllers e colocar **portas (in/out)** + **use cases** no lugar certo.

> **Estado (refatoração aplicada):** controllers e `application` não dependem mais de `*JpaRepository`. Persistência JPA fica em `adapter.out.persistence`. O domínio expõe `DeviceRepositoryPort` + modelo `Device`, e `TaskPersistencePort` + modelo `Task` (`com.automation.core.domain.port.out`); `TaskPersistenceAdapter` mapeia `TaskEntity` ↔ `Task`. `TaskService` e claim de tarefa usam `Device` via `DeviceRepositoryPort` (sem `DeviceEntityPersistencePort`). Demais agregados ainda podem usar `application.port.out.*` com entidades JPA até migração gradual. Entrada HTTP mapeia para `application.input.*` onde aplicável.

---

## 1. Problema original (histórico)

- **Controller** injetava e usava direto repositórios JPA.
- Orquestração espalhada no controller.
- Pouca separação entre adapter web e casos de uso.

---

## 2. Visão alvo (hexagonal)

```
  HTTP Request
       │
       ▼
  Controller (adapter IN)   ──chama──►  Port IN (use case)   ──usa──►  Port OUT (interface)
       │                                      │                              │
       │                                      │ implementa                   │ implementa
       │                                      ▼                              ▼
       │                              Use Case (application)         Adapter OUT (persistence)
       │                                      │                              │
       │                                      └──────────usa─────────────────┘
       │
       ▼
  HTTP Response (mapeia resultado do use case)
```

- **Controller**: só recebe request, chama **um** use case (port in), mapeia resultado para response.
- **Use case**: contém a lógica; depende só de **portas out** (interfaces).
- **Adapter out**: implementa as portas out e usa JPA por dentro.

---

## 3. Passos concretos

### 3.1 Criar Ports OUT (application)

As portas **out** ficam na aplicação (ou no domain). O use case depende delas, não do JPA.

**Pacote sugerido:** `com.automation.core.application.port.out`

Exemplo para Sales Order:

- **SalesOrderPersistencePort**  
  - `Optional<SalesOrderEntity> findById(Long id)`  
  - `List<SalesOrderEntity> findByCreatedByIdOrderByCreatedAtDesc(Long createdById)`  
  - `List<SalesOrderEntity> findAll()`  
  - `SalesOrderEntity save(SalesOrderEntity order)`  
  - `void delete(SalesOrderEntity order)`  

- **CustomerPersistencePort** – `Optional<CustomerEntity> findById(Long id)`  
- **RangeServerPersistencePort** – `Optional<RangeServerEntity> findById(Long id)`  
- **UserPersistencePort** – `Optional<UserEntity> findById(Long id)`  
- **TaskPersistencePort** – `long countBySalesOrderId(Long salesOrderId)` (e o que mais o use case precisar)

Nota: hoje o retorno ainda pode ser entidade (JPA); o importante é o use case depender da **interface** no pacote da aplicação. Se quiser deixar o núcleo 100% livre de JPA, depois você introduz modelos de domínio e as portas passam a usar esses tipos (adapter faz Entity ↔ Domain).

### 3.2 Implementar os Adapters OUT (persistence)

Criar classes que **implementam** essas portas e delegam para os repositórios JPA existentes.

**Pacote:** `com.automation.core.adapter.out.persistence` (ou subpasta `adapter`)

Exemplos:

- **SalesOrderPersistenceAdapter** implements **SalesOrderPersistencePort**  
  - Injeta `SalesOrderRepository` (JpaRepository)  
  - `findById` → `salesOrderRepository.findById(id)`  
  - `save` → `salesOrderRepository.save(order)`  
  - etc.

- **CustomerPersistenceAdapter** implements **CustomerPersistencePort** (delega para `CustomerJpaRepository`)
- Idem para RangeServer, User, Task (só os que o use case de Sales Order precisar).

Assim, a **lógica** e as **regras** saem do controller e não dependem de JPA; só o adapter out depende.

### 3.3 Criar Use Cases (application)

**Pacote sugerido:** `com.automation.core.application.service` ou `com.automation.core.application.usecase`

Exemplo: **CreateSalesOrderUseCase** (ou **SalesOrderApplicationService** com método `create`).

- Recebe: `SaleOrderCreateRequest` (ou um DTO de aplicação equivalente).
- Depende de: `SalesOrderPersistencePort`, `CustomerPersistencePort`, `RangeServerPersistencePort`, `UserPersistencePort`.
- Faz:
  - Buscar user, customer, range (via ports).
  - Se não existir → falha (erro que o controller traduz em 404).
  - Calcular `tasksTotal`, `priority` (mover `computePriority` para cá).
  - Montar e persistir a ordem (via `SalesOrderPersistencePort.save`).
  - Retornar o que o controller precisa para montar o 201 (ex.: a entidade salva ou um DTO de resultado).

Idem para **UpdateSalesOrderUseCase**, **DeleteSalesOrderUseCase**, **ListSalesOrderUseCase**, **GetSalesOrderByIdUseCase**: cada um usa só as portas out necessárias e concentra a regra (ex.: “não apagar se tiver tasks” no delete).

Para **Tasks**: **ListTasksUseCase**, **GetTaskByIdUseCase**, **UpdateTaskStatusUseCase**, etc., dependendo de portas out de Task (e se precisar, de SalesOrder). A lógica de filtro (salesOrderId, statusTask) e de atualização de status fica no use case, não no controller.

### 3.4 Port IN (use case como “porta de entrada”)

A **port in** é o contrato que o controller chama. Duas opções:

- **Opção A (simples):** o controller injeta a classe do use case (ex.: `CreateSalesOrderUseCase`) e chama `create(request)`. O use case **é** a implementação da port in.
- **Opção B:** definir uma interface em `application.port.in`, ex.: `CreateSalesOrderPort`, e o use case implementa essa interface. O controller depende da interface.

Para começar, a Opção A basta: controller depende do use case; o use case depende das portas out.

### 3.5 Deixar o Controller fino

**SalesOrderController:**

- Injeta: `CreateSalesOrderUseCase`, `UpdateSalesOrderUseCase`, `DeleteSalesOrderUseCase`, um use case para list/get (ou um único `SalesOrderApplicationService` com vários métodos).
- **Não** injeta mais: `SalesOrderRepository`, `CustomerJpaRepository`, `RangeServerJpaRepository`, `UserJpaRepository`, `TaskJpaRepository`.
- `create(request)`:
  - Chama `createSalesOrderUseCase.create(request)`.
  - Se retorno for erro (ex.: “cliente não encontrado”) → 404 com mensagem.
  - Se sucesso → 201 e `toResponse(result)` (mapeamento entidade/DTO → `SalesOrderResponse`).
- `update`, `delete`, `list`, `getById`: só delegam para o use case correspondente e mapeiam resultado/erro para HTTP.

**TaskController:**

- Injeta: use cases (ex.: `ListTasksUseCase`, `GetTaskByIdUseCase`, `UpdateTaskStatusUseCase`).
- **Não** injeta mais: `TaskJpaRepository`.
- List/get/updateStatus: chamam o use case e mapeiam para `TaskResponse` e status HTTP.

O controller continua responsável **apenas** por: HTTP, validação do request (DTO), chamada ao use case e mapeamento do resultado/erro para resposta HTTP.

### 3.6 Registrar os adapters e use cases no Spring

- As implementações das portas out (ex.: `SalesOrderPersistenceAdapter`) devem ser beans (ex.: `@Component`).
- Os use cases também (`@Service` ou `@Component`).
- O controller recebe o use case por construtor; o use case recebe as portas out por construtor. Como as portas out são interfaces implementadas pelos adapters, o Spring injeta os adapters nos use cases.

Se uma porta out tiver mais de uma implementação, usar `@Qualifier` ou um único adapter que agrupe os repositórios necessários.

---

## 4. Ordem sugerida de implementação

1. **Sales Order**
   - Criar portas out (SalesOrder, Customer, RangeServer, User, Task) em `application.port.out`.
   - Criar adapters em `adapter.out.persistence` que implementam essas portas.
   - Criar use cases (create, update, delete, list, getById) em `application.service` (ou `application.usecase`).
   - Refatorar `SalesOrderController` para depender só dos use cases e mapear resultados.
2. **Task**
   - Criar portas out de Task (e SalesOrder se precisar) em `application.port.out`.
   - Implementar adapters e use cases (list, getById, updateStatus).
   - Refatorar `TaskController` para depender só dos use cases.
3. Repetir o mesmo padrão para os outros controllers que ainda tiverem lógica e dependência direta em repositórios (Customer, Device, Auth, etc.).

---

## 5. Resumo

| O que fazer | Onde |
|-------------|------|
| Portas OUT (interfaces de persistência) | `application.port.out` |
| Implementação das portas OUT (usa JPA) | `adapter.out.persistence` (adapters) |
| Use cases (lógica + regras) | `application.service` ou `application.usecase` |
| Controller só chama use case e mapeia HTTP | `adapter.in.web.controller` |

Com isso você tira as dependências e a lógica dos controllers e passa a seguir o hexagonal de forma correta: **port in = use case**, **port out = interfaces de persistência**, **controller = adapter in**, **repositórios JPA = usados só nos adapters out**.
