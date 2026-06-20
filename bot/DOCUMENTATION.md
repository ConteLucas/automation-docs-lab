# 📚 AUTOMATION BOT DDT - DOCUMENTAÇÃO COMPLETA

## 🎯 VISÃO GERAL

Bot de automação Android para DDTank BR usando MVVM pattern, Clean Architecture e Kotlin Coroutines.

---

## 🏗️ ARQUITETURA

```
┌─────────────────────────────────────────────────────────────┐
│                        USUÁRIO                               │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    MainActivity (UI)                         │
│  - Botões: START/PAUSE, STOP                                │
│  - Delega tudo para BotController                           │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│              BotController (Presentation)                    │
│  - Gerencia ESTADO (IDLE/RUNNING/PAUSED)                    │
│  - Coordena: AppLauncher + Orchestrator                     │
└────────┬────────────────────────────────┬───────────────────┘
         │                                │
         ▼                                ▼
┌─────────────────┐          ┌──────────────────────────────┐
│   AppLauncher   │          │  AutomationOrchestrator      │
│ - launch()      │          │  - executeLoginFlow()        │
│ - forceStop()   │          │  - executeNextStep()         │
└─────────────────┘          └──────────┬───────────────────┘
                                        │
                                        ▼
                             ┌──────────────────────────────┐
                             │    FlowLoginUseCase          │
                             │  1. Valida tela login        │
                             │  2. Clica coordenada         │
                             └──┬─────────────┬─────────────┘
                                │             │
                ┌───────────────┘             └─────────────────┐
                ▼                                               ▼
    ┌───────────────────────┐                     ┌────────────────────┐
    │  ScreenValidator      │                     │   ScreenClicker    │
    │ - validateScreen()    │                     │ - click(coord)     │
    │ - retry logic         │                     │ - clickAt(x,y)     │
    └───────┬───────────────┘                     └────────────────────┘
            │                                               │
            ▼                                               ▼
    ┌───────────────────────┐                     ┌────────────────────┐
    │  VisionApiService     │                     │ "input tap X Y"    │
    │  (Mock - 95%)         │                     │ + ClickEffect      │
    └───────────────────────┘                     └────────────────────┘
```

---

## 📁 ESTRUTURA DO PROJETO

```
automation-bot-ddt/
├── app/src/main/java/com/automation/bot/
│   ├── presentation/controller/
│   │   └── BotController.kt          ← Estado + Coordenação
│   ├── domain/
│   │   ├── orchestrator/
│   │   │   └── AutomationOrchestrator.kt ← Orquestra fluxos
│   │   ├── usecases/
│   │   │   ├── FlowLoginUseCase.kt   ← Lógica de login
│   │   │   └── ScreenValidator.kt    ← Valida telas
│   │   ├── constants/AppConstants.kt ← Constantes
│   │   └── enums/
│   │       ├── GameScreen.kt         ← Códigos telas
│   │       └── GameCoordinate.kt     ← Coordenadas
│   ├── automation/
│   │   ├── AppLauncher.kt            ← Abre/fecha apps
│   │   └── ScreenClicker.kt          ← Clicks + efeito
│   ├── ui/
│   │   ├── MainActivity.kt           ← UI principal
│   │   ├── FloatingLogWindow.kt      ← Float sobre jogo
│   │   └── ClickEffectOverlay.kt     ← Efeito visual
│   ├── utils/LogFileManager.kt       ← Logs em arquivo
│   └── api/VisionApiService.kt       ← Mock Vision
└── logs/                              ← Logs sincronizados
```

---

## 🎮 FUNCIONALIDADES IMPLEMENTADAS

### 1. Controle do Bot
- ✅ Botões START/PAUSE/STOP na MainActivity
- ✅ Gerenciamento de estado (IDLE/RUNNING/PAUSED)
- ✅ Abertura/fechamento automático do DDT

### 2. Janela Flutuante
- ✅ Draggable (pode arrastar)
- ✅ Expand/Collapse
- ✅ Botões: ▶/⏸ (Play/Pause), ✕ (Close), ─ (Minimize)
- ✅ Mostra: Login, Level, Runtime, Logs
- ✅ Auto-scroll nos logs

### 3. Validação de Tela
- ✅ Template Matching (mockado - retorna 95%)
- ✅ Retry logic (5 tentativas, 2s entre cada)
- ✅ Confidence threshold (90%)
- ✅ GameScreen enum com códigos

### 4. Click com Efeito Visual
- ✅ Círculo verde expandindo + fade out
- ✅ Duração 400ms
- ✅ GameCoordinate enum (LOGIN_BTN_ENTER: 1238, 1125)

### 5. Logs Completos
- ✅ 3 destinos: MainActivity, Float, Arquivo
- ✅ Arquivo: `/sdcard/Download/automation-bot-ddt/logs/`
- ✅ Formato: `bot_log_YYYY-MM-DD_HH-mm-ss.txt`
- ✅ Timestamp em cada entrada
- ✅ Header + Footer com duração

---

## 🔄 FLUXO DE AUTOMAÇÃO

```
1. Usuário clica START
   ↓
2. BotController.start()
   ↓
3. AppLauncher.launch(DDT)
   ↓
4. Aguarda 3s
   ↓
5. AutomationOrchestrator.executeLoginFlow()
   ↓
6. FlowLoginUseCase.execute()
   ├─ ScreenValidator.validateScreenWithRetry(LOGIN_SCREEN)
   │  ├─ Attempt 1/5 for screen (LOGIN_SCREEN)
   │  ├─ VisionApiService.matchTemplate() → 95%
   │  └─ Screen matched (LOGIN_SCREEN) - confidence: 95.00%
   ├─ Aguarda 1s
   └─ ScreenClicker.click(LOGIN_BTN_ENTER)
      ├─ Mostra efeito visual (círculo verde)
      └─ Runtime.exec("input tap 1238 1125")
```

---

## 🎨 INTERFACE

### MainActivity
```
┌──────────────────────────────────┐
│  Bot DDT - Automation            │
│  ════════════════════════════    │
│                                  │
│  Status: Running                 │
│                                  │
│  [START/PAUSE]  [STOP]           │
│                                  │
│  ════════════════════════════    │
│  Logs:                           │
│  > Bot started                   │
│  > Opening DDT game...           │
│  > DDT launched successfully     │
│  > Waiting screenshot...         │
└──────────────────────────────────┘
```

### FloatingLogWindow
```
┌─────────────────────────────────────┐
│  DDT Bot     ▶ ✕ ─                 │
│                                     │
│  Login:      account01              │
│  Level:      ??                     │
│  Runtime:    00:02:34               │
│                                     │
│  Execution Logs                     │
│  > Opening DDT game...              │
│  > DDT launched successfully        │
│  > Waiting screenshot (LOGIN_...)   │
│  > Screen matched (LOGIN_SCREEN)    │
│  > Click coordinate (LOGIN_BTN_...) │
└─────────────────────────────────────┘
```

---

## 📊 LOGS DETALHADOS

### Formato do Log em Arquivo:
```
═══════════════════════════════════════════════════
DDT BOT - EXECUTION LOG
═══════════════════════════════════════════════════
Start Time: 2026-02-15 14:30:00
Path: /sdcard/Download/automation-bot-ddt/logs/bot_log_2026-02-15_14-30-00.txt
═══════════════════════════════════════════════════

[2026-02-15 14:30:00] Bot started
[2026-02-15 14:30:02] Waiting 2000ms before launch...
[2026-02-15 14:30:04] Opening DDT game (com.road7.ddtankbr.gp)
[2026-02-15 14:30:05] DDT launched successfully
[2026-02-15 14:30:08] Waiting screenshot (LOGIN_SCREEN)
[2026-02-15 14:30:08] Attempt 1/5 for screen (LOGIN_SCREEN)
[2026-02-15 14:30:09] Screen matched (LOGIN_SCREEN) - confidence: 95.00%
[2026-02-15 14:30:10] Click coordinate (LOGIN_BTN_ENTER) at X:1238 Y:1125

═══════════════════════════════════════════════════
End Time: 2026-02-15 14:35:45
Total Duration: 00:05:45
═══════════════════════════════════════════════════
```

---

## 🛠️ CONSTANTES E ENUMS

### AppConstants.kt
```kotlin
const val DDTANK_PACKAGE = "com.road7.ddtankbr.gp"
const val DEFAULT_ACCOUNT = "account01"
const val DEFAULT_LEVEL = "??"
const val DELAY_BEFORE_LAUNCH = 2000L
const val DELAY_BEFORE_VALIDATION = 3000L
const val DELAY_BEFORE_CLICK = 1000L
const val MAX_VALIDATION_ATTEMPTS = 5
const val DELAY_BETWEEN_ATTEMPTS = 2000L
const val MIN_CONFIDENCE_THRESHOLD = 0.90f
```

### GameScreen.kt
```kotlin
enum class GameScreen(val code: String, val templatePath: String) {
    LOGIN_SCREEN("LOGIN_SCREEN", "templates/ddt/login/screen_login.png"),
    MENU_SCREEN("MENU_SCREEN", "templates/ddt/menu/screen_menu.png")
}
```

### GameCoordinate.kt
```kotlin
enum class GameCoordinate(val code: String, val x: Int, val y: Int) {
    LOGIN_BTN_ENTER("LOGIN_BTN_ENTER", 1238, 1125),
    LOGIN_BTN_CANCEL("LOGIN_BTN_CANCEL", 640, 800)
}
```

---

## 🚀 COMO USAR

### 1. Build e Install:
```bash
cd automation-bot-ddt
./run.sh
```

### 2. Usar o Bot:
1. Abra o app "Bot DDT"
2. Conceda permissão de overlay
3. Clique START
4. Janela flutuante aparece
5. Bot abre DDT automaticamente
6. Valida tela de login
7. Clica no botão de entrada

### 3. Controles:
- **▶/⏸** Play/Pause dinâmico
- **✕** Fecha app (com confirmação)
- **─** Minimiza janela
- **STOP** Para bot (na MainActivity)

### 4. Ver Logs:
```bash
# Listar
adb -s emulator-5556 shell ls /sdcard/Download/automation-bot-ddt/logs/

# Baixar
adb -s emulator-5556 pull /sdcard/Download/automation-bot-ddt/logs/ ./logs/

# Ver conteúdo
adb -s emulator-5556 shell cat /sdcard/Download/automation-bot-ddt/logs/bot_log_*.txt
```

---

## 📝 PRÓXIMOS PASSOS

### Curto Prazo:
1. ❌ Implementar screenshot real (MediaProjection API)
2. ❌ Adicionar template real de tela de login
3. ❌ Integrar Vision API real

### Médio Prazo:
4. ❌ Adicionar mais telas (MENU, BATTLE, etc)
5. ❌ Mais coordenadas (botões, menus)
6. ❌ Sequências de ações automatizadas

### Longo Prazo:
7. ❌ Database para coordenadas
8. ❌ Múltiplas contas
9. ❌ Sistema de tasks
10. ❌ BFF + Frontend

---

## 🎯 PADRÕES DE CÓDIGO

### Nomenclatura:
- ✅ Tudo em **inglês**
- ✅ Sem emojis
- ✅ "DDT" ao invés de "DDTank BR"
- ✅ Logs claros e concisos

### Arquitetura:
- ✅ **Clean Architecture**
- ✅ **MVVM Pattern**
- ✅ **Single Responsibility**
- ✅ **Separation of Concerns**

### Organização:
- ✅ Constants em `AppConstants.kt`
- ✅ Enums em `domain/enums/`
- ✅ UseCases em `domain/usecases/`
- ✅ Orchestration em `domain/orchestrator/`
- ✅ UI em `ui/`
- ✅ Utils em `utils/`

---

## 📞 REFERÊNCIAS RÁPIDAS

### Pacotes Importantes:
- **Presentation:** `com.automation.bot.presentation.controller`
- **Domain:** `com.automation.bot.domain.*`
- **UI:** `com.automation.bot.ui`
- **Automation:** `com.automation.bot.automation`
- **Utils:** `com.automation.bot.utils`

### Classes Principais:
- **BotController** - Gerencia estado
- **AutomationOrchestrator** - Orquestra fluxos
- **FlowLoginUseCase** - Lógica de login
- **ScreenValidator** - Valida telas
- **ScreenClicker** - Executa clicks
- **FloatingLogWindow** - Janela flutuante
- **LogFileManager** - Logs em arquivo

---

**Status:** ✅ Compilado e funcionando
**Versão:** 1.0
**Última Atualização:** 2026-02-15
