# 🚀 Histórias Técnicas - Plataforma DDT

**Última atualização**: 9 de Março de 2026  
**Status**: Documentação de Implementação  
**Orçamento**: ZERO (AWS Free Tier + Alternativas Gratuitas)

---

## 📊 Índice

1. [Visão Geral](#visão-geral)
2. [Estado Atual (março 2026)](#estado-atual-março-2026)
3. [Stack Tecnológica](#stack-tecnológica)
4. [Arquitetura de Custos Zero](#arquitetura-de-custos-zero)
5. [Ordem de Implementação](#ordem-de-implementação)
6. [Histórias Técnicas Detalhadas](#histórias-técnicas-detalhadas)

---

## 🎯 Visão Geral

### Objetivo
Construir uma plataforma de automação Android distribuída, onde:
- **Core API** orquestra tasks
- **Bot Android (APK)** executa tasks usando UIAutomator2 nativo
- **BFF** serve o frontend
- **OCR** processa imagens (opcional - pode ser local no Bot)

### Restrições
- ✅ **Orçamento ZERO**
- ✅ AWS Free Tier (12 meses)
- ✅ Alternativas gratuitas quando AWS não for viável
- ✅ Escalabilidade horizontal quando possível

---

## 📌 Estado Atual (março 2026)

- **automation-core-ddt:** Spring Boot 3 + JPA/Hibernate, PostgreSQL. Entidades: `range_server` (com `description`), `server` (65 servidores, vinculados a ranges), `game_account` (login único), `game_details_account` (1:N por conta, UNIQUE por conta+server), além de `customer`, `device`, `sales_order`, `task`, etc. APIs REST documentadas no Swagger; batch de inserção via `/api/*/batch`.
- **Massas:** Dados iniciais em `scripts/massas/` (JSON) para carga na ordem: permission → range_server → server → customer → game_account → game_details_account. Ver [scripts/massas/README.MD](scripts/massas/README.MD).
- **automation-bot-ddt:** App Android (Kotlin); backup de versões em `backup/bot/` (v3, v4, v5). v5 reflete refatoração 1:N game_account ↔ game_details_account e login único.
- **Documentação:** [docs/core/CORE-DATABASE-TABLES.md](docs/core/CORE-DATABASE-TABLES.md) (schema e relacionamentos), [docs/REPOSITORIES-OVERVIEW.md](docs/REPOSITORIES-OVERVIEW.md) (visão dos repositórios).

---

## 🛠️ Stack Tecnológica

### ☁️ Backend (Orquestrador)
| Componente | Tecnologia | Justificativa |
|------------|------------|---------------|
| **Core API** | Java 17 + Spring Boot 3.1 | Já existe, robusto, free |
| **Build** | Maven | Já configurado |
| **Database** | PostgreSQL 15 | AWS RDS Free Tier (db.t3.micro, 20GB) |
| **Cache/Queue** | Redis ou In-Memory | ElastiCache free tier OU implementação local |
| **Storage** | S3 | 5GB free tier para screenshots |
| **Deploy** | Railway.app / Render.com | **FREE tier ilimitado** (melhor que EC2) |

### 📱 Bot Android (Worker)
| Componente | Tecnologia | Justificativa |
|------------|------------|---------------|
| **Linguagem** | Kotlin 1.9+ | Moderna, segura, Android oficial |
| **UI Automation** | UIAutomator2 (androidx.test.uiautomator) | Nativo Android, SEM Appium |
| **OCR** | Tesseract4Android OU Google ML Kit | Processamento LOCAL (zero custo cloud) |
| **HTTP Client** | Retrofit 2.9 | Leve, eficiente |
| **Async** | Kotlin Coroutines | Nativo, performático |
| **DI** | Koin | Mais leve que Hilt |
| **Deploy** | APK direto | Distribuição manual ou Firebase App Distribution (free) |

### 🌐 BFF (API Gateway)
| Componente | Tecnologia | Justificativa |
|------------|------------|---------------|
| **Framework** | Node.js 20 + Express.js | Leve, rápido, free deploy |
| **Auth** | JWT (jsonwebtoken) | Stateless, sem database extra |
| **Deploy** | Vercel / Railway | **FREE tier ilimitado** |

### 🔍 OCR Service (Opcional)
| Opção | Tecnologia | Recomendação |
|-------|------------|--------------|
| **Opção 1** | Integrado no Bot (Tesseract4Android) | ✅ **RECOMENDADO** - Zero custo |
| **Opção 2** | Python + FastAPI + Tesseract | Somente se precisar processamento pesado |

### 🎨 Frontend (Futuro)
| Componente | Tecnologia | Deploy |
|------------|------------|--------|
| **Framework** | React 18 + Vite | Vercel / Netlify (free) |
| **UI** | shadcn/ui (Tailwind) | Sem custo de licença |

---

## 💰 Arquitetura de Custos Zero

### 🆓 Recursos Free Tier (12 meses)

#### AWS Free Tier
```
✅ EC2 t2.micro        : 750 horas/mês (1 instância 24/7)
✅ RDS db.t3.micro     : 750 horas/mês + 20GB storage
✅ S3                  : 5GB storage + 20k GET + 2k PUT
✅ ElastiCache         : Não tem free tier ❌
✅ Lambda              : 1M requisições/mês (não vamos usar)
```

#### ⚠️ PROBLEMA: AWS Free Tier tem pegadinhas
- Expira em 12 meses
- Fácil ultrapassar limites
- Custos inesperados

### 🎯 SOLUÇÃO: Alternativas 100% Gratuitas

#### Railway.app (RECOMENDADO para Core API)
```
✅ $5 de crédito/mês GRÁTIS (forever)
✅ Deploy automático via GitHub
✅ PostgreSQL incluído (1GB)
✅ Redis incluído
✅ Logs, métricas, rollback
✅ Custom domains
✅ Zero configuração

Limitações:
- 500MB RAM (suficiente para Spring Boot otimizado)
- $5/mês de compute (≈ 100 horas uptime)
- Fica offline quando não usar todo mês
```

#### Render.com (Alternativa)
```
✅ Totalmente FREE (sem créditos, sem limites de tempo)
✅ PostgreSQL free (90 dias, depois expira DB mas app continua)
✅ Deploy via GitHub
✅ SSL automático

Limitações:
- 512MB RAM
- Spin down após 15min inatividade (cold start ~30s)
- 750 horas/mês (= 24/7 com 1 serviço)
```

#### Vercel (RECOMENDADO para BFF)
```
✅ 100% FREE (sem limites de tempo)
✅ Deploy automático via GitHub
✅ Edge Functions (serverless)
✅ Global CDN

Perfeito para:
- Node.js API
- Frontend React
```

#### Supabase (RECOMENDADO para PostgreSQL)
```
✅ PostgreSQL free ilimitado
✅ 500MB database
✅ 1GB file storage
✅ 50k monthly active users
✅ Auth incluído (se precisar)

Melhor que AWS RDS para começar!
```

### 🏆 Arquitetura Final (Custo Zero)

```
┌─────────────────────────────────────────────────┐
│  FRONTEND (React)                               │
│  Deploy: Vercel (FREE forever)                  │
└────────────────┬────────────────────────────────┘
                 │ HTTPS
┌────────────────▼────────────────────────────────┐
│  BFF (Node.js + Express)                        │
│  Deploy: Vercel Edge Functions (FREE forever)   │
│  Auth: JWT (stateless)                          │
└────────────────┬────────────────────────────────┘
                 │ HTTPS
┌────────────────▼────────────────────────────────┐
│  CORE API (Spring Boot)                         │
│  Deploy: Railway.app ($5 free/mês)              │
│  Cache: In-Memory (Caffeine) - sem Redis        │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│  POSTGRESQL                                      │
│  Deploy: Supabase (FREE forever)                │
│  Storage: 500MB (suficiente para MVP)           │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│  BOT WORKERS (Android APK)                       │
│  📱 Device 1, 2, 3, N...                         │
│  - UIAutomator2 (local)                          │
│  - OCR local (Tesseract4Android)                 │
│  - Polling: GET /tasks/available                 │
│  Deploy: APK manual ou Firebase App Distribution │
└──────────────────────────────────────────────────┘

💰 CUSTO TOTAL: R$ 0,00/mês
```

---

## 📅 Ordem de Implementação

### Sprint 0: Preparação (2-3 dias)
- [ ] Criar contas gratuitas (Railway, Supabase, Vercel)
- [ ] Configurar repositório Git
- [ ] Definir estrutura de branches
- [ ] Setup CI/CD básico

### Sprint 1: Core API - Endpoints para Workers (5-7 dias)
**História Técnica #1**

### Sprint 2: Core API - Sistema de Fila de Tasks (3-5 dias)
**História Técnica #2**

### Sprint 3: Deploy Core em Railway (1-2 dias)
**História Técnica #3**

### Sprint 4: Bot Android - Setup e Estrutura (3-5 dias)
**História Técnica #4**

### Sprint 5: Bot Android - UIAutomator2 + Comunicação (7-10 dias)
**História Técnica #5**

### Sprint 6: Bot Android - OCR Local (3-5 dias)
**História Técnica #6**

### Sprint 7: Integração Core ↔ Bot (2-3 dias)
**História Técnica #7**

### Sprint 8: BFF API Gateway (5-7 dias)
**História Técnica #8**

### Sprint 9: Frontend Dashboard (10-15 dias)
**História Técnica #9** (futuro)

---

## 📋 Histórias Técnicas Detalhadas

---

## 🎫 História Técnica #1: Core API - Endpoints para Workers

**Sprint**: 1  
**Prioridade**: 🔴 CRÍTICA  
**Estimativa**: 5-7 dias  
**Dependências**: Nenhuma  

### 📝 Descrição
Implementar endpoints REST no Core API para comunicação com Workers Android (Bots). Os Workers farão polling para buscar tasks, solicitar contas e enviar resultados.

### 🎯 Objetivo
Permitir que Workers Android se comuniquem com o Core para:
1. Buscar tasks disponíveis
2. Solicitar alocação de contas
3. Enviar resultados de execução
4. Enviar heartbeat (status do device)
5. Obter configurações

### 📐 Arquitetura

#### Endpoints a Criar
```
GET    /api/v1/worker/tasks/available?deviceId={id}
POST   /api/v1/worker/accounts/request
PUT    /api/v1/worker/tasks/{taskId}/result
POST   /api/v1/worker/devices/heartbeat
GET    /api/v1/worker/config/latest
POST   /api/v1/worker/register
```

#### Estrutura de Pacotes
```
com.automation/
├── application/
│   ├── dto/
│   │   ├── TaskRequestDTO.java           [NOVO]
│   │   ├── TaskResponseDTO.java          [NOVO]
│   │   ├── AccountRequestDTO.java        [NOVO]
│   │   ├── TaskResultDTO.java            [NOVO]
│   │   ├── DeviceHeartbeatDTO.java       [NOVO]
│   │   ├── WorkerConfigDTO.java          [NOVO]
│   │   └── DeviceRegistrationDTO.java    [NOVO]
│   │
│   └── services/
│       ├── WorkerTaskService.java        [NOVO]
│       ├── AccountAllocationService.java [NOVO]
│       └── DeviceManagementService.java  [NOVO]
│
└── infrastructure/
    └── adapters/
        └── input/
            └── web/
                └── WorkerController.java  [NOVO]
```

### 🔧 Implementação Detalhada

#### 1. Criar DTOs

**TaskRequestDTO.java**
```java
package com.automation.application.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class TaskRequestDTO {
    private String deviceId;
    private String workerVersion;
    private LocalDateTime timestamp;
}
```

**TaskResponseDTO.java**
```java
package com.automation.application.dto;

import lombok.Data;
import java.util.Map;

@Data
public class TaskResponseDTO {
    private Long id;
    private Long orderId;
    private String type;  // LOGIN, DAILY_QUEST, LEVEL_UP, etc.
    private Integer priority;
    private Map<String, Object> parameters;
    private String status;
    private LocalDateTime createdAt;
}
```

**AccountRequestDTO.java**
```java
package com.automation.application.dto;

import lombok.Data;

@Data
public class AccountRequestDTO {
    private String deviceId;
    private Long taskId;
    
    // Critérios de seleção
    private Integer maxLevel;        // Ex: level < 30
    private String serverGroup;      // Ex: "BR"
    private Long serverId;          // Ex: específico
}
```

**AccountResponseDTO.java**
```java
package com.automation.application.dto;

import lombok.Data;

@Data
public class AccountResponseDTO {
    private Long id;
    private String username;
    private String password;
    private String email;
    private Integer level;
    private Long serverId;
    private String serverName;
    private LocalDateTime allocatedAt;
    private LocalDateTime expiresAt;  // Tempo máximo de uso
}
```

**TaskResultDTO.java**
```java
package com.automation.application.dto;

import lombok.Data;
import java.util.Map;

@Data
public class TaskResultDTO {
    private String status;  // completed, failed, error
    private Map<String, Object> data;
    private String error;
    private Integer executionTimeMs;
    private String screenshot;  // Base64 encoded
    private LocalDateTime completedAt;
}
```

**DeviceHeartbeatDTO.java**
```java
package com.automation.application.dto;

import lombok.Data;

@Data
public class DeviceHeartbeatDTO {
    private String deviceId;
    private String status;  // online, idle, busy
    private Integer batteryLevel;
    private Long memoryUsedMb;
    private Long memoryTotalMb;
    private String currentTaskId;
    private LocalDateTime timestamp;
}
```

**WorkerConfigDTO.java**
```java
package com.automation.application.dto;

import lombok.Data;

@Data
public class WorkerConfigDTO {
    private Long version;
    private Integer pollIntervalMs;
    private Integer heartbeatIntervalMs;
    private Integer maxRetries;
    private String gamePackage;
    private Map<String, Object> customSettings;
}
```

**DeviceRegistrationDTO.java**
```java
package com.automation.application.dto;

import lombok.Data;

@Data
public class DeviceRegistrationDTO {
    private String deviceId;
    private String model;
    private String manufacturer;
    private String androidVersion;
    private String workerVersion;
    private Integer screenWidth;
    private Integer screenHeight;
}
```

#### 2. Criar Services

**WorkerTaskService.java**
```java
package com.automation.application.services;

import com.automation.application.dto.*;
import com.automation.domain.model.OrderTask;
import com.automation.infrastructure.adapters.output.persistence.OrderTaskRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class WorkerTaskService {
    
    private final OrderTaskRepository orderTaskRepository;
    
    /**
     * Busca próxima task disponível para o worker
     */
    @Transactional
    public Optional<TaskResponseDTO> getNextAvailableTask(String deviceId) {
        log.info("Device {} requesting next task", deviceId);
        
        // Busca primeira task com status "pending"
        Optional<OrderTask> taskOpt = orderTaskRepository
            .findFirstByStatusOrderByPriorityDescCreatedAtAsc("pending");
        
        if (taskOpt.isEmpty()) {
            log.debug("No tasks available for device {}", deviceId);
            return Optional.empty();
        }
        
        OrderTask task = taskOpt.get();
        
        // Marca como "assigned" para este device
        task.setStatus("assigned");
        task.setAssignedDeviceId(deviceId);
        task.setAssignedAt(LocalDateTime.now());
        orderTaskRepository.save(task);
        
        log.info("Task {} assigned to device {}", task.getId(), deviceId);
        
        return Optional.of(mapToDTO(task));
    }
    
    /**
     * Atualiza resultado da task
     */
    @Transactional
    public void updateTaskResult(Long taskId, TaskResultDTO result) {
        log.info("Updating task {} with status {}", taskId, result.getStatus());
        
        OrderTask task = orderTaskRepository.findById(taskId)
            .orElseThrow(() -> new RuntimeException("Task not found: " + taskId));
        
        task.setStatus(result.getStatus());
        task.setResult(result.getData());
        task.setError(result.getError());
        task.setExecutionTimeMs(result.getExecutionTimeMs());
        task.setCompletedAt(LocalDateTime.now());
        
        orderTaskRepository.save(task);
        
        log.info("Task {} updated successfully", taskId);
    }
    
    private TaskResponseDTO mapToDTO(OrderTask task) {
        TaskResponseDTO dto = new TaskResponseDTO();
        dto.setId(task.getId());
        dto.setOrderId(task.getOrderId());
        dto.setType(task.getType());
        dto.setPriority(task.getPriority());
        dto.setParameters(task.getParameters());
        dto.setStatus(task.getStatus());
        dto.setCreatedAt(task.getCreatedAt());
        return dto;
    }
}
```

**AccountAllocationService.java**
```java
package com.automation.application.services;

import com.automation.application.dto.*;
import com.automation.domain.model.Account;
import com.automation.infrastructure.adapters.output.persistence.AccountRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class AccountAllocationService {
    
    private final AccountRepository accountRepository;
    private static final int ALLOCATION_TIMEOUT_MINUTES = 30;
    
    /**
     * Aloca uma conta disponível baseada nos critérios
     */
    @Transactional
    public AccountResponseDTO allocateAccount(AccountRequestDTO request) {
        log.info("Allocating account for device {} with criteria: maxLevel={}, serverGroup={}", 
            request.getDeviceId(), request.getMaxLevel(), request.getServerGroup());
        
        // Busca conta disponível
        Account account = accountRepository
            .findAvailableAccount(request.getMaxLevel(), request.getServerGroup())
            .orElseThrow(() -> new RuntimeException("No accounts available matching criteria"));
        
        // Marca como em uso
        account.setStatus("in_use");
        account.setAllocatedToDeviceId(request.getDeviceId());
        account.setAllocatedAt(LocalDateTime.now());
        account.setExpiresAt(LocalDateTime.now().plusMinutes(ALLOCATION_TIMEOUT_MINUTES));
        accountRepository.save(account);
        
        log.info("Account {} allocated to device {}", account.getId(), request.getDeviceId());
        
        return mapToDTO(account);
    }
    
    /**
     * Libera conta após uso
     */
    @Transactional
    public void releaseAccount(Long accountId) {
        log.info("Releasing account {}", accountId);
        
        Account account = accountRepository.findById(accountId)
            .orElseThrow(() -> new RuntimeException("Account not found: " + accountId));
        
        account.setStatus("available");
        account.setAllocatedToDeviceId(null);
        account.setAllocatedAt(null);
        account.setExpiresAt(null);
        accountRepository.save(account);
        
        log.info("Account {} released", accountId);
    }
    
    private AccountResponseDTO mapToDTO(Account account) {
        AccountResponseDTO dto = new AccountResponseDTO();
        dto.setId(account.getId());
        dto.setUsername(account.getUsername());
        dto.setPassword(account.getPassword());
        dto.setEmail(account.getEmail());
        dto.setLevel(account.getLevel());
        dto.setServerId(account.getServerId());
        dto.setAllocatedAt(account.getAllocatedAt());
        dto.setExpiresAt(account.getExpiresAt());
        return dto;
    }
}
```

**DeviceManagementService.java**
```java
package com.automation.application.services;

import com.automation.application.dto.*;
import com.automation.domain.model.Device;
import com.automation.infrastructure.adapters.output.persistence.DeviceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class DeviceManagementService {
    
    private final DeviceRepository deviceRepository;
    
    /**
     * Registra novo device
     */
    @Transactional
    public Device registerDevice(DeviceRegistrationDTO dto) {
        log.info("Registering device {}", dto.getDeviceId());
        
        // Verifica se já existe
        Device device = deviceRepository.findByDeviceId(dto.getDeviceId())
            .orElse(new Device());
        
        device.setDeviceId(dto.getDeviceId());
        device.setModel(dto.getModel());
        device.setManufacturer(dto.getManufacturer());
        device.setAndroidVersion(dto.getAndroidVersion());
        device.setWorkerVersion(dto.getWorkerVersion());
        device.setScreenWidth(dto.getScreenWidth());
        device.setScreenHeight(dto.getScreenHeight());
        device.setStatus("online");
        device.setLastSeenAt(LocalDateTime.now());
        
        if (device.getId() == null) {
            device.setRegisteredAt(LocalDateTime.now());
        }
        
        deviceRepository.save(device);
        log.info("Device {} registered successfully", dto.getDeviceId());
        
        return device;
    }
    
    /**
     * Atualiza heartbeat do device
     */
    @Transactional
    public void updateHeartbeat(DeviceHeartbeatDTO heartbeat) {
        log.debug("Heartbeat from device {}: battery={}, memory={}/{}", 
            heartbeat.getDeviceId(), 
            heartbeat.getBatteryLevel(),
            heartbeat.getMemoryUsedMb(),
            heartbeat.getMemoryTotalMb());
        
        Device device = deviceRepository.findByDeviceId(heartbeat.getDeviceId())
            .orElseThrow(() -> new RuntimeException("Device not found: " + heartbeat.getDeviceId()));
        
        device.setStatus(heartbeat.getStatus());
        device.setBatteryLevel(heartbeat.getBatteryLevel());
        device.setMemoryUsedMb(heartbeat.getMemoryUsedMb());
        device.setLastSeenAt(LocalDateTime.now());
        
        deviceRepository.save(device);
    }
    
    /**
     * Retorna configuração mais recente para worker
     */
    public WorkerConfigDTO getLatestConfig() {
        WorkerConfigDTO config = new WorkerConfigDTO();
        config.setVersion(1L);
        config.setPollIntervalMs(10000);  // 10 segundos
        config.setHeartbeatIntervalMs(30000);  // 30 segundos
        config.setMaxRetries(3);
        config.setGamePackage("com.example.game");  // TODO: buscar do DB
        return config;
    }
}
```

#### 3. Criar Controller

**WorkerController.java**
```java
package com.automation.infrastructure.adapters.input.web;

import com.automation.application.dto.*;
import com.automation.application.services.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/api/v1/worker")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Worker API", description = "Endpoints para Workers Android")
public class WorkerController {
    
    private final WorkerTaskService workerTaskService;
    private final AccountAllocationService accountAllocationService;
    private final DeviceManagementService deviceManagementService;
    
    /**
     * Worker solicita próxima task disponível
     */
    @GetMapping("/tasks/available")
    @Operation(summary = "Buscar próxima task disponível")
    public ResponseEntity<TaskResponseDTO> getAvailableTask(
            @RequestParam String deviceId,
            @RequestHeader(value = "X-API-Key", required = false) String apiKey) {
        
        log.info("Request for available task from device: {}", deviceId);
        
        // TODO: Validar API Key
        
        Optional<TaskResponseDTO> task = workerTaskService.getNextAvailableTask(deviceId);
        
        return task.map(ResponseEntity::ok)
                   .orElse(ResponseEntity.noContent().build());
    }
    
    /**
     * Worker solicita alocação de conta
     */
    @PostMapping("/accounts/request")
    @Operation(summary = "Solicitar alocação de conta")
    public ResponseEntity<AccountResponseDTO> requestAccount(
            @RequestBody AccountRequestDTO request,
            @RequestHeader(value = "X-API-Key", required = false) String apiKey) {
        
        log.info("Account request from device: {}", request.getDeviceId());
        
        try {
            AccountResponseDTO account = accountAllocationService.allocateAccount(request);
            return ResponseEntity.ok(account);
        } catch (RuntimeException e) {
            log.error("Failed to allocate account: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).build();
        }
    }
    
    /**
     * Worker envia resultado da task
     */
    @PutMapping("/tasks/{taskId}/result")
    @Operation(summary = "Enviar resultado da task")
    public ResponseEntity<Void> submitTaskResult(
            @PathVariable Long taskId,
            @RequestBody TaskResultDTO result,
            @RequestHeader(value = "X-API-Key", required = false) String apiKey) {
        
        log.info("Task result received for task: {}", taskId);
        
        try {
            workerTaskService.updateTaskResult(taskId, result);
            
            // Se task completou, libera a conta
            if ("completed".equals(result.getStatus()) || "failed".equals(result.getStatus())) {
                // TODO: buscar accountId da task e liberar
            }
            
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            log.error("Failed to update task result: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }
    
    /**
     * Worker envia heartbeat
     */
    @PostMapping("/devices/heartbeat")
    @Operation(summary = "Enviar heartbeat do device")
    public ResponseEntity<Void> heartbeat(
            @RequestBody DeviceHeartbeatDTO heartbeat,
            @RequestHeader(value = "X-API-Key", required = false) String apiKey) {
        
        try {
            deviceManagementService.updateHeartbeat(heartbeat);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            log.error("Failed to update heartbeat: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }
    
    /**
     * Worker solicita configuração mais recente
     */
    @GetMapping("/config/latest")
    @Operation(summary = "Obter configuração mais recente")
    public ResponseEntity<WorkerConfigDTO> getLatestConfig(
            @RequestParam String deviceId,
            @RequestHeader(value = "X-API-Key", required = false) String apiKey) {
        
        WorkerConfigDTO config = deviceManagementService.getLatestConfig();
        return ResponseEntity.ok(config);
    }
    
    /**
     * Registrar novo worker
     */
    @PostMapping("/register")
    @Operation(summary = "Registrar novo worker")
    public ResponseEntity<Void> registerWorker(
            @RequestBody DeviceRegistrationDTO registration,
            @RequestHeader(value = "X-API-Key", required = false) String apiKey) {
        
        log.info("Registering worker: {}", registration.getDeviceId());
        
        deviceManagementService.registerDevice(registration);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }
}
```

### 🗄️ Mudanças no Banco de Dados

#### Adicionar colunas em `order_tasks`
```sql
ALTER TABLE order_tasks
ADD COLUMN assigned_device_id VARCHAR(255),
ADD COLUMN assigned_at TIMESTAMP,
ADD COLUMN completed_at TIMESTAMP,
ADD COLUMN execution_time_ms INTEGER,
ADD COLUMN result JSONB,
ADD COLUMN error TEXT;
```

#### Adicionar colunas em `accounts`
```sql
ALTER TABLE accounts
ADD COLUMN status VARCHAR(50) DEFAULT 'available',
ADD COLUMN allocated_to_device_id VARCHAR(255),
ADD COLUMN allocated_at TIMESTAMP,
ADD COLUMN expires_at TIMESTAMP;

CREATE INDEX idx_accounts_status ON accounts(status);
```

#### Criar tabela `devices`
```sql
CREATE TABLE devices (
    id BIGSERIAL PRIMARY KEY,
    device_id VARCHAR(255) UNIQUE NOT NULL,
    model VARCHAR(255),
    manufacturer VARCHAR(255),
    android_version VARCHAR(50),
    worker_version VARCHAR(50),
    screen_width INTEGER,
    screen_height INTEGER,
    status VARCHAR(50) DEFAULT 'offline',
    battery_level INTEGER,
    memory_used_mb BIGINT,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_devices_device_id ON devices(device_id);
CREATE INDEX idx_devices_status ON devices(status);
```

### ✅ Critérios de Aceitação

- [ ] Endpoint `GET /api/v1/worker/tasks/available` retorna task ou 204
- [ ] Endpoint `POST /api/v1/worker/accounts/request` aloca conta corretamente
- [ ] Endpoint `PUT /api/v1/worker/tasks/{id}/result` atualiza status da task
- [ ] Endpoint `POST /api/v1/worker/devices/heartbeat` atualiza status do device
- [ ] Endpoint `GET /api/v1/worker/config/latest` retorna configuração
- [ ] Endpoint `POST /api/v1/worker/register` registra novo device
- [ ] Tasks pendentes são atribuídas apenas uma vez
- [ ] Contas são marcadas como "em uso" e liberadas após task
- [ ] Documentação Swagger atualizada
- [ ] Logs informativos em todos os endpoints
- [ ] Testes unitários dos services
- [ ] Testes de integração dos endpoints

### 🧪 Testes

#### Teste Manual com curl
```bash
# 1. Buscar task disponível
curl -X GET "http://localhost:8080/api/v1/worker/tasks/available?deviceId=test-device-123" \
  -H "X-API-Key: test-key"

# 2. Solicitar conta
curl -X POST "http://localhost:8080/api/v1/worker/accounts/request" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test-key" \
  -d '{
    "deviceId": "test-device-123",
    "taskId": 1,
    "maxLevel": 30,
    "serverGroup": "BR"
  }'

# 3. Enviar resultado
curl -X PUT "http://localhost:8080/api/v1/worker/tasks/1/result" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test-key" \
  -d '{
    "status": "completed",
    "data": {"xp_gained": 1000},
    "executionTimeMs": 45000
  }'

# 4. Enviar heartbeat
curl -X POST "http://localhost:8080/api/v1/worker/devices/heartbeat" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test-key" \
  -d '{
    "deviceId": "test-device-123",
    "status": "idle",
    "batteryLevel": 85,
    "memoryUsedMb": 1200,
    "memoryTotalMb": 4096
  }'
```

### 📊 Métricas de Sucesso
- Response time < 200ms (endpoints GET)
- Response time < 500ms (endpoints POST/PUT)
- Zero race conditions na alocação de tasks/contas
- Logs claros para debugging

---

## 🎫 História Técnica #2: Core API - Sistema de Fila de Tasks

**Sprint**: 2  
**Prioridade**: 🟡 ALTA  
**Estimativa**: 3-5 dias  
**Dependências**: História #1  

### 📝 Descrição
Implementar sistema de fila de tasks para distribuição eficiente entre Workers. Começaremos com **implementação em memória** (zero custo) e depois podemos migrar para Redis se necessário.

### 🎯 Objetivo
- Distribuir tasks de forma justa entre Workers
- Prevenir que múltiplos Workers peguem a mesma task
- Permitir retry de tasks falhadas
- Priorizar tasks por urgência

### 🔧 Implementação

#### Opção 1: In-Memory Queue (RECOMENDADO para MVP)
**Vantagens**:
- ✅ Zero custo
- ✅ Zero dependências externas
- ✅ Simples de implementar
- ✅ Suficiente para 10-50 Workers

**Desvantagens**:
- ❌ Perde fila se aplicação reiniciar (mitigado com persistência no PostgreSQL)
- ❌ Não funciona com múltiplas instâncias do Core (não é problema no início)

#### Opção 2: Redis (para futuro)
**Quando migrar**:
- Quando tiver >50 Workers
- Quando precisar de múltiplas instâncias do Core
- Quando Railway der crédito suficiente

### 📐 Arquitetura In-Memory Queue

```java
package com.automation.application.services;

import com.automation.domain.model.OrderTask;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.PriorityBlockingQueue;
import java.util.concurrent.ConcurrentHashMap;

@Service
@Slf4j
public class TaskQueueService {
    
    // Fila de tasks ordenada por prioridade
    private final BlockingQueue<OrderTask> taskQueue = 
        new PriorityBlockingQueue<>(100, (t1, t2) -> {
            // Ordena por: prioridade DESC, createdAt ASC
            int priorityCompare = Integer.compare(t2.getPriority(), t1.getPriority());
            if (priorityCompare != 0) return priorityCompare;
            return t1.getCreatedAt().compareTo(t2.getCreatedAt());
        });
    
    // Mapa de tasks em processamento (para evitar duplicação)
    private final ConcurrentHashMap<Long, String> assignedTasks = new ConcurrentHashMap<>();
    
    /**
     * Adiciona task na fila
     */
    public void enqueue(OrderTask task) {
        log.info("Enqueueing task {} with priority {}", task.getId(), task.getPriority());
        taskQueue.offer(task);
    }
    
    /**
     * Worker pega próxima task disponível
     */
    public Optional<OrderTask> dequeue(String deviceId) {
        try {
            OrderTask task = taskQueue.poll();
            if (task != null) {
                // Marca como atribuída
                assignedTasks.put(task.getId(), deviceId);
                log.info("Task {} dequeued by device {}", task.getId(), deviceId);
                return Optional.of(task);
            }
        } catch (Exception e) {
            log.error("Error dequeueing task", e);
        }
        return Optional.empty();
    }
    
    /**
     * Remove task da lista de atribuídas (quando completa)
     */
    public void completeTask(Long taskId) {
        assignedTasks.remove(taskId);
        log.info("Task {} marked as completed", taskId);
    }
    
    /**
     * Retry de task (volta para fila)
     */
    public void retryTask(OrderTask task) {
        assignedTasks.remove(task.getId());
        task.setStatus("pending");
        enqueue(task);
        log.info("Task {} re-queued for retry", task.getId());
    }
    
    /**
     * Estatísticas da fila
     */
    public QueueStats getStats() {
        return new QueueStats(
            taskQueue.size(),
            assignedTasks.size()
        );
    }
    
    public record QueueStats(int pending, int assigned) {}
}
```

#### Integração com WorkerTaskService

```java
@Service
@RequiredArgsConstructor
public class WorkerTaskService {
    
    private final TaskQueueService taskQueueService;
    private final OrderTaskRepository orderTaskRepository;
    
    /**
     * Busca próxima task (agora usa fila)
     */
    @Transactional
    public Optional<TaskResponseDTO> getNextAvailableTask(String deviceId) {
        // 1. Tenta pegar da fila
        Optional<OrderTask> taskOpt = taskQueueService.dequeue(deviceId);
        
        if (taskOpt.isEmpty()) {
            // 2. Se fila vazia, busca do DB e enfileira
            refreshQueueFromDatabase();
            taskOpt = taskQueueService.dequeue(deviceId);
        }
        
        if (taskOpt.isEmpty()) {
            return Optional.empty();
        }
        
        OrderTask task = taskOpt.get();
        
        // 3. Atualiza no DB
        task.setStatus("assigned");
        task.setAssignedDeviceId(deviceId);
        task.setAssignedAt(LocalDateTime.now());
        orderTaskRepository.save(task);
        
        return Optional.of(mapToDTO(task));
    }
    
    /**
     * Recarrega fila do banco de dados
     */
    private void refreshQueueFromDatabase() {
        List<OrderTask> pendingTasks = orderTaskRepository
            .findByStatusOrderByPriorityDesc("pending");
        
        for (OrderTask task : pendingTasks) {
            taskQueueService.enqueue(task);
        }
        
        log.info("Refreshed queue with {} tasks", pendingTasks.size());
    }
    
    /**
     * Task completada
     */
    @Transactional
    public void updateTaskResult(Long taskId, TaskResultDTO result) {
        // Atualiza no DB
        OrderTask task = orderTaskRepository.findById(taskId)
            .orElseThrow(() -> new RuntimeException("Task not found: " + taskId));
        
        task.setStatus(result.getStatus());
        task.setResult(result.getData());
        task.setCompletedAt(LocalDateTime.now());
        orderTaskRepository.save(task);
        
        // Remove da fila de atribuídas
        taskQueueService.completeTask(taskId);
        
        // Se falhou e tem retries, volta pra fila
        if ("failed".equals(result.getStatus()) && task.getRetryCount() < 3) {
            task.setRetryCount(task.getRetryCount() + 1);
            taskQueueService.retryTask(task);
        }
    }
}
```

#### Endpoint de Monitoramento

```java
@RestController
@RequestMapping("/api/v1/admin")
public class AdminController {
    
    @Autowired
    private TaskQueueService taskQueueService;
    
    @GetMapping("/queue/stats")
    public ResponseEntity<TaskQueueService.QueueStats> getQueueStats() {
        return ResponseEntity.ok(taskQueueService.getStats());
    }
}
```

### ✅ Critérios de Aceitação
- [ ] Tasks são enfileiradas por prioridade
- [ ] Múltiplos Workers não pegam a mesma task
- [ ] Tasks falhadas são re-enfileiradas automaticamente
- [ ] Fila é recarregada do DB quando vazia
- [ ] Endpoint de monitoramento funciona
- [ ] Performance: dequeue < 50ms

---

## 🎫 História Técnica #3: Deploy Core em Railway.app

**Sprint**: 3  
**Prioridade**: 🟡 ALTA  
**Estimativa**: 1-2 dias  
**Dependências**: História #1, #2  

### 📝 Descrição
Fazer deploy do Core API em Railway.app (FREE tier) com PostgreSQL incluído.

### 🎯 Objetivo
Ter Core API rodando em produção com custo ZERO.

### 🔧 Passo a Passo

#### 1. Criar conta no Railway
```
1. Acesse railway.app
2. Sign up com GitHub
3. Conecte repositório automation-learn
```

#### 2. Criar `railway.json`
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "mvn clean install -DskipTests -pl automation-core-ddt"
  },
  "deploy": {
    "startCommand": "java -jar automation-core-ddt/target/automation-core-ddt-1.0.jar",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
```

#### 3. Otimizar `application.yml` para Railway
```yaml
spring:
  application:
    name: automation-core-ddt
  
  datasource:
    url: ${DATABASE_URL}  # Railway injeta automaticamente
    driver-class-name: org.postgresql.Driver
  
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: false
  
server:
  port: ${PORT:8080}  # Railway define a porta

logging:
  level:
    root: INFO
    com.automation: DEBUG
```

#### 4. Reduzir consumo de memória (importante!)
```yaml
# application.yml
spring:
  jpa:
    properties:
      hibernate:
        jdbc:
          batch_size: 20
    open-in-view: false

# Opções de JVM (criar arquivo Procfile ou railway.json)
```

**Procfile**
```
web: java -Xmx400m -Xms256m -jar automation-core-ddt/target/automation-core-ddt-1.0.jar
```

#### 5. Deploy
```bash
# Instalar Railway CLI
npm install -g @railway/cli

# Login
railway login

# Criar projeto
railway init

# Deploy
railway up

# Ver logs
railway logs
```

#### 6. Adicionar PostgreSQL
```
1. No dashboard do Railway
2. Clique em "New" → "Database" → "PostgreSQL"
3. Railway cria DATABASE_URL automaticamente
4. Core vai usar automaticamente
```

### ✅ Critérios de Aceitação
- [ ] Core rodando em Railway
- [ ] PostgreSQL conectado
- [ ] Swagger acessível: https://your-app.railway.app/swagger-ui.html
- [ ] Logs visíveis no dashboard
- [ ] Health check funcionando
- [ ] Consumo < 500MB RAM

---

*(Continua com Histórias #4-#9...)*

Quer que eu continue com as próximas histórias técnicas (Bot Android, BFF, etc)?
