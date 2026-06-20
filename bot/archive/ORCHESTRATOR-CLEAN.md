# ORCHESTRATOR - CLEAN ARCHITECTURE

## 📋 O que foi refatorado

O `AutomationOrchestrator` foi simplificado seguindo os princípios de Clean Architecture.

---

## 🎯 Antes vs Depois

### ❌ ANTES (Poluído)

```kotlin
class AutomationOrchestrator(
    private val menuLoginUseCase: MenuLoginUseCase,
    private val floatingLog: FloatingLogWindow,  // ❌ Dependência de UI
    private val onLog: ((String) -> Unit)?       // ❌ Gerenciando logs
) {
    
    suspend fun executeLoginFlow(): Result<Unit> {
        return try {
            // ❌ Muitos logs manualmente
            val validateLog = "Validating login screen..."
            Timber.i(validateLog)
            onLog?.invoke(validateLog)
            floatingLog.log(validateLog)
            
            val result = menuLoginUseCase.execute()
            
            if (result.isSuccess) {
                val match = result.getOrNull()
                val successLog = "Login screen detected!"
                val confidenceLog = "Confidence: ${String.format("%.1f", match?.confidence?.times(100))}%"
                
                // ❌ Mais logs...
                Timber.i(successLog)
                onLog?.invoke(successLog)
                floatingLog.log(successLog)
                floatingLog.log(confidenceLog)
                floatingLog.log("════════════════════")
                floatingLog.log("Login button clicked!")
                floatingLog.log("Ready to proceed!")
                
                Result.success(Unit)
            } else {
                // ❌ Ainda mais logs...
                val errorLog = "Login screen not found"
                val checkLog = "Please check if game loaded correctly"
                
                Timber.w(errorLog)
                onLog?.invoke(errorLog)
                floatingLog.log(errorLog)
                floatingLog.log(checkLog)
                
                Result.failure(Exception("Login screen not detected"))
            }
            
        } catch (e: Exception) {
            // ❌ Logs de erro
            val errorMsg = "Error in login flow: ${e.message}"
            Timber.e(e, errorMsg)
            onLog?.invoke(errorMsg)
            floatingLog.log("Error: ${e.message}")
            
            Result.failure(e)
        }
    }
}
```

**Problemas:**
- ❌ Responsável por logging (não é sua função)
- ❌ Dependência de UI (`FloatingLogWindow`)
- ❌ Código poluído com logs repetitivos
- ❌ Difícil de testar
- ❌ Viola Single Responsibility Principle

---

### ✅ DEPOIS (Limpo)

```kotlin
class AutomationOrchestrator(
    private val menuLoginUseCase: MenuLoginUseCase  // ✅ Apenas use cases
) {
    
    /**
     * Execute login flow
     * 
     * Flow:
     * 1. Validate login screen
     * 2. Click login button
     * 
     * @return Result.success if login completed, Result.failure otherwise
     */
    suspend fun executeLoginFlow(): Result<Unit> {
        return try {
            val loginResult = menuLoginUseCase.execute()
            
            if (loginResult.isFailure) {
                val error = loginResult.exceptionOrNull() 
                    ?: Exception("Login flow failed")
                return Result.failure(error)
            }
            
            Result.success(Unit)
            
        } catch (exception: Exception) {
            Timber.e(exception, "Login flow crashed")
            Result.failure(exception)
        }
    }
    
    suspend fun executeMainMenuFlow(): Result<Unit> {
        return Result.failure(
            NotImplementedError("Main menu flow not implemented yet")
        )
    }
    
    suspend fun executeBattleFlow(): Result<Unit> {
        return Result.failure(
            NotImplementedError("Battle flow not implemented yet")
        )
    }
}
```

**Benefícios:**
- ✅ Foco em orquestração de fluxos
- ✅ Sem dependências de UI
- ✅ Logs delegados aos use cases
- ✅ Código limpo e legível
- ✅ Fácil de testar
- ✅ Segue Single Responsibility Principle

---

## 🏗️ Arquitetura de Responsabilidades

```
┌─────────────────────────────────────────────────────────┐
│ PRESENTATION LAYER                                      │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ BotViewModel                                        │ │
│ │ - Manages UI state (IDLE/RUNNING/PAUSED)           │ │
│ │ - Handles user interactions                         │ │
│ │ - Observes flows                                    │ │
│ └─────────────────────────────────────────────────────┘ │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│ DOMAIN LAYER                                            │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ StartBotUseCase                                     │ │
│ │ - Opens DDT                                         │ │
│ │ - Calls orchestrator                                │ │
│ └─────────────────────────────────────────────────────┘ │
│                         │                               │
│                         ▼                               │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ AutomationOrchestrator ← YOU ARE HERE               │ │
│ │ ✅ Coordinates use cases                            │ │
│ │ ✅ Validates results                                │ │
│ │ ✅ Handles flow transitions                         │ │
│ │ ✅ Try-catch for flow crashes                       │ │
│ │ ❌ Does NOT log details                             │ │
│ │ ❌ Does NOT execute actions                         │ │
│ └─────────────────────────────────────────────────────┘ │
│                         │                               │
│                         ▼                               │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ MenuLoginUseCase                                    │ │
│ │ ✅ Validates login screen                           │ │
│ │ ✅ Clicks login button                              │ │
│ │ ✅ Logs all actions                                 │ │
│ │ ✅ Handles retries                                  │ │
│ └─────────────────────────────────────────────────────┘ │
│              │                    │                     │
│              ▼                    ▼                     │
│ ┌──────────────────┐  ┌─────────────────────────────┐  │
│ │ ScreenValidator  │  │ ScreenClicker               │  │
│ │ - Validates      │  │ - Executes click            │  │
│ │ - Logs attempts  │  │ - Shows visual effect       │  │
│ └──────────────────┘  └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 📐 Princípios Aplicados

### 1️⃣ **Single Responsibility Principle (SRP)**

Cada classe tem **uma única responsabilidade**:

| Classe | Responsabilidade |
|--------|------------------|
| `AutomationOrchestrator` | Coordenar fluxos de automação |
| `MenuLoginUseCase` | Executar fluxo de login |
| `ScreenValidator` | Validar screenshots |
| `ScreenClicker` | Executar clicks |

### 2️⃣ **Dependency Inversion Principle (DIP)**

Orchestrator depende de **abstrações** (interfaces), não de implementações concretas:

```kotlin
class AutomationOrchestrator(
    private val menuLoginUseCase: MenuLoginUseCase  // ✅ Depende de use case
    // ❌ Não depende de FloatingLogWindow (UI concreta)
)
```

### 3️⃣ **Separation of Concerns**

Cada camada tem suas próprias preocupações:

```
┌──────────────────┬─────────────────────────────────────┐
│ Camada           │ Preocupações                        │
├──────────────────┼─────────────────────────────────────┤
│ Orchestrator     │ Coordenar, validar, decidir         │
│ Use Cases        │ Executar ações, logar, tratar erros │
│ ViewModel        │ Gerenciar estado UI                 │
│ Activity         │ Renderizar UI, capturar eventos     │
└──────────────────┴─────────────────────────────────────┘
```

---

## 🔄 Fluxo de Execução

```
1. User clicks START
   ↓
2. BotViewModel.start()
   ↓
3. StartBotUseCase.execute()
   ├─ Opens DDT
   ├─ Logs: "Launching DDT..."
   ├─ Waits 3s
   └─ Calls orchestrator.executeLoginFlow()
   ↓
4. AutomationOrchestrator.executeLoginFlow()
   ├─ Calls menuLoginUseCase.execute()
   ├─ Validates result
   ├─ Returns Result<Unit>
   └─ Only logs if CRASH occurs
   ↓
5. MenuLoginUseCase.execute()
   ├─ Logs: "Starting login screen validation..."
   ├─ Calls screenValidator.validateScreenWithRetry()
   ├─ Logs: "Attempt 1/5 for screen (0009)"
   ├─ Logs: "Screen matched (0009) - confidence: 95%"
   ├─ Calls screenClicker.click()
   ├─ Logs: "Click coordinate (2929) at X:1238 Y:1125"
   └─ Logs: "Login button clicked successfully"
```

**Observe:**
- Orchestrator **não loga** detalhes de execução
- Orchestrator apenas **coordena** e **valida**
- Use Cases **fazem** o trabalho e **logam** as ações

---

## 🧪 Testabilidade

### ANTES (Difícil de testar)

```kotlin
// ❌ Precisa mockar FloatingLogWindow, onLog callback
val orchestrator = AutomationOrchestrator(
    menuLoginUseCase = mockLoginUseCase,
    floatingLog = mockFloatingLog,
    onLog = mockLogCallback
)
```

### DEPOIS (Fácil de testar)

```kotlin
// ✅ Apenas mocka use case
val orchestrator = AutomationOrchestrator(
    menuLoginUseCase = mockLoginUseCase
)

// Test
val result = orchestrator.executeLoginFlow()
assertTrue(result.isSuccess)
```

---

## 🎯 Como Adicionar Novos Fluxos

### Exemplo: Battle Flow

```kotlin
// 1. Criar Use Case
class BattleLobbyUseCase(
    context: Context,
    visionApi: VisionApiService,
    private val onLog: ((String) -> Unit)?
) {
    suspend fun execute(): Result<Unit> {
        // Valida tela de battle
        // Seleciona arma
        // Logs detalhados aqui
    }
}

// 2. Adicionar no Orchestrator
class AutomationOrchestrator(
    private val menuLoginUseCase: MenuLoginUseCase,
    private val battleLobbyUseCase: BattleLobbyUseCase  // ✅ Nova dependência
) {
    
    suspend fun executeBattleFlow(): Result<Unit> {
        return try {
            // 1. Enter lobby
            val lobbyResult = battleLobbyUseCase.execute()
            if (lobbyResult.isFailure) {
                return Result.failure(
                    lobbyResult.exceptionOrNull() ?: Exception("Battle lobby failed")
                )
            }
            
            // 2. Select weapon (future)
            // 3. Aim and shoot (future)
            
            Result.success(Unit)
            
        } catch (exception: Exception) {
            Timber.e(exception, "Battle flow crashed")
            Result.failure(exception)
        }
    }
}

// 3. Chamar no StartBotUseCase
class StartBotUseCase(...) {
    suspend fun execute(): Result<Unit> {
        // 1. Login flow
        orchestrator.executeLoginFlow()
        
        // 2. Battle flow
        orchestrator.executeBattleFlow()  // ✅ Novo fluxo
    }
}
```

---

## 📊 Comparação de Linhas de Código

| Métrica | ANTES | DEPOIS | Redução |
|---------|-------|--------|---------|
| Linhas de código | 63 | 76 | +21% (por adicionar flows futuros) |
| Dependências | 3 | 1 | -67% |
| Statements de log | 15 | 1 | -93% |
| Responsabilidades | 3 | 1 | -67% |
| Testabilidade | Baixa | Alta | +∞ |

---

## ✅ Checklist de Código Limpo

Para verificar se seu código está seguindo Clean Architecture:

- [x] Orchestrator não tem dependências de UI?
- [x] Orchestrator não faz logging detalhado?
- [x] Orchestrator apenas coordena use cases?
- [x] Use cases fazem o trabalho real?
- [x] Use cases fazem logging?
- [x] Fácil de testar?
- [x] Sem variáveis com nomes ruins (i, r, e)?
- [x] Try-catch apenas para crashes críticos?

---

## 🚀 Próximos Fluxos a Implementar

Com o Orchestrator limpo, você pode adicionar:

1. **Main Menu Flow**
   - Validar menu principal
   - Navegar para seções
   - Coletar recursos diários

2. **Battle Flow**
   - Entrar no lobby
   - Selecionar arma
   - Mirar e atirar
   - Aguardar turno

3. **Resource Flow**
   - Navegar para loja
   - Coletar gold
   - Comprar itens

---

## 📝 Exemplo Completo de Fluxo Futuro

```kotlin
class StartBotUseCase(...) {
    suspend fun execute(): Result<Unit> {
        return try {
            // 1. Login
            val loginResult = orchestrator.executeLoginFlow()
            if (loginResult.isFailure) return loginResult
            
            delay(2000)
            
            // 2. Main Menu
            val menuResult = orchestrator.executeMainMenuFlow()
            if (menuResult.isFailure) return menuResult
            
            delay(2000)
            
            // 3. Collect Daily Resources
            val resourceResult = orchestrator.executeResourceFlow()
            if (resourceResult.isFailure) return resourceResult
            
            delay(2000)
            
            // 4. Enter Battle
            val battleResult = orchestrator.executeBattleFlow()
            if (battleResult.isFailure) return battleResult
            
            Result.success(Unit)
            
        } catch (exception: Exception) {
            Timber.e(exception, "Bot execution crashed")
            Result.failure(exception)
        }
    }
}
```

---

## 🎓 Lições Aprendidas

1. **Orchestrator = Coordenador**
   - Não executa, apenas orquestra
   - Não loga, apenas valida
   - Não conhece UI, apenas use cases

2. **Use Cases = Executores**
   - Fazem o trabalho real
   - Logam detalhadamente
   - Tratam erros específicos

3. **Separation of Concerns**
   - Cada classe tem uma única responsabilidade
   - Fácil de entender, testar e manter

4. **Clean Code**
   - Nomes descritivos (não `i`, `r`, `e`)
   - Comentários apenas quando necessário
   - Código auto-explicativo
