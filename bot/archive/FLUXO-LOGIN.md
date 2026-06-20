# FLUXO LOGIN - DIAGRAMA DE SEQUÊNCIA

## 📊 Visão Geral

Este documento explica o fluxo completo de validação e click na tela de login.

---

## 🔄 Sequência de Execução

```
┌──────────┐   ┌─────────────┐   ┌─────────────┐   ┌──────────────┐   ┌─────────────────┐   ┌─────────────────┐   ┌──────────────┐
│ Usuario  │   │ MainActivity│   │BotViewModel │   │StartBotUseCase│   │AutomationOrch...│   │MenuLoginUseCase│   │ScreenClicker │
└────┬─────┘   └──────┬──────┘   └──────┬──────┘   └───────┬──────┘   └────────┬────────┘   └────────┬────────┘   └──────┬───────┘
     │                │                 │                   │                    │                     │                   │
     │ 1. Click START │                 │                   │                    │                     │                   │
     │───────────────>│                 │                   │                    │                     │                   │
     │                │                 │                   │                    │                     │                   │
     │                │ 2. start()      │                   │                    │                     │                   │
     │                │────────────────>│                   │                    │                     │                   │
     │                │                 │                   │                    │                     │                   │
     │                │                 │ State = RUNNING   │                    │                     │                   │
     │                │                 │ startNewLog()     │                    │                     │                   │
     │                │                 │ floatingLog.show()│                    │                     │                   │
     │                │                 │                   │                    │                     │                   │
     │                │                 │ 3. execute()      │                    │                     │                   │
     │                │                 │──────────────────>│                    │                     │                   │
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │ 4. Launch DDT      │                     │                   │
     │                │                 │                   │ appLauncher.launch()                     │                   │
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │ Log: "Launching DDT..."                   │                   │
     │                │                 │                   │───────────────────────────────────────────────────────────────>│
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │ 5. Wait 3s         │                     │                   │
     │                │                 │                   │ delay(3000)        │                     │                   │
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │ Log: "Waiting 3s..." │                   │                   │
     │                │                 │                   │───────────────────────────────────────────────────────────────>│
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │ 6. executeLoginFlow()                    │                   │
     │                │                 │                   │───────────────────>│                     │                   │
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │                    │ 7. execute()        │                   │
     │                │                 │                   │                    │────────────────────>│                   │
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │                    │                     │ Log: "Starting..."│
     │                │                 │                   │                    │                     │──────────────────>│
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │                    │                     │ 8. Validate Screen│
     │                │                 │                   │                    │                     │ screenValidator   │
     │                │                 │                   │                    │                     │ .validateScreen() │
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │                    │                     │ Log: "Waiting (0009)"
     │                │                 │                   │                    │                     │──────────────────>│
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │                    │                     │ Retry 5x          │
     │                │                 │                   │                    │                     │ Take screenshot   │
     │                │                 │                   │                    │                     │ Compare with      │
     │                │                 │                   │                    │                     │ assets/0009.png   │
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │                    │                     │ MOCK:             │
     │                │                 │                   │                    │                     │ return 95% match  │
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │                    │                     │ Log: "Matched (0009) 95%"
     │                │                 │                   │                    │                     │──────────────────>│
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │                    │                     │ 9. Wait 1s        │
     │                │                 │                   │                    │                     │ delay(1000)       │
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │                    │                     │ Log: "Waiting 1s..."
     │                │                 │                   │                    │                     │──────────────────>│
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │                    │                     │ 10. Click         │
     │                │                 │                   │                    │                     │────────────────────────────>│
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │                    │                     │ Log: "Click (2929) X:1238 Y:1125"
     │                │                 │                   │                    │                     │──────────────────>│
     │                │                 │                   │                    │                     │                   │
     │                │                 │                   │                    │                     │                   │ Show Effect
     │                │                 │                   │                    │                     │                   │ Execute:
     │                │                 │                   │                    │                     │                   │ adb input
     │                │                 │                   │                    │                     │                   │ tap 1238 1125
     │                │ ◄───────────────────────────────────────────────────────────────────────────────────────────────────┘
     │                │                 │                   │                    │                     │                   
     │ See Logs       │                 │                   │                    │                     │                   
     │ in Float       │                 │                   │                    │                     │                   
     │ & Main App     │                 │                   │                    │                     │                   
     │◄───────────────┘                 │                   │                    │                     │                   
     │                                  │                   │                    │                     │                   
```

---

## 📝 Explicação Passo a Passo

### 1️⃣ **Usuário Clica START**
- Location: `MainActivity.kt:128`
- Action: `btnStartPause.setOnClickListener`

### 2️⃣ **BotViewModel.start()**
- Location: `BotViewModel.kt:52`
- Actions:
  - Muda estado para `RUNNING`
  - Inicia novo arquivo de log
  - Mostra floating window
  - Lança coroutine com `startBotUseCase.execute()`

### 3️⃣ **StartBotUseCase.execute()**
- Location: `StartBotUseCase.kt`
- Verifica se DDT está rodando
- Se não, lança o app

### 4️⃣ **Launch DDT**
- Location: `StartBotUseCase.kt`
- `appLauncher.launch("com.road7.ddtankbr.gp")`
- Log: `"Launching DDT..."`

### 5️⃣ **Wait 3s**
- Location: `StartBotUseCase.kt`
- `delay(3000)`
- Aguarda o app carregar
- Log: `"Waiting 3s for DDT to load..."`

### 6️⃣ **AutomationOrchestrator.executeLoginFlow()**
- Location: `AutomationOrchestrator.kt`
- Chama `menuLoginUseCase.execute()`

### 7️⃣ **MenuLoginUseCase.execute()**
- Location: `MenuLoginUseCase.kt:23`
- Log: `"Starting login screen validation..."`

### 8️⃣ **Screen Validation**
- Location: `ScreenValidator.kt`
- Log: `"Waiting screenshot menu page (0009)"`
- Tenta 5x com delay de 2s entre tentativas
- Cada tentativa:
  1. Tira screenshot (mocked)
  2. Compara com `assets/templates/ddt/login/screen_login.png`
  3. Verifica threshold (90%)
- **MOCK sempre retorna**: `isMatch: true, confidence: 0.95`
- Log success: `"Screen matched (0009) - confidence: 95.00%"`

### 9️⃣ **Wait Before Click**
- Location: `MenuLoginUseCase.kt:38`
- `delay(1000)`
- Log: `"Waiting 1000ms before click..."`

### 🔟 **Execute Click**
- Location: `ScreenClicker.kt:19`
- Coordinates: `LOGIN_BTN_ENTER (code: 2929) → X:1238, Y:1125`
- Log: `"Click coordinate (2929) at X:1238 Y:1125"`
- Actions:
  1. Show visual effect (green circle)
  2. Execute: `adb shell input tap 1238 1125`
  3. Log: `"Executing click at (1238, 1125)"`

---

## 📁 Arquivos Envolvidos

| Arquivo | Responsabilidade |
|---------|------------------|
| `MainActivity.kt` | Interface do usuário, botões START/STOP/PAUSE |
| `BotViewModel.kt` | Gerencia estado (IDLE/RUNNING/PAUSED), coordena use cases |
| `BotFactory.kt` | Dependency Injection, cria todas as dependências |
| `StartBotUseCase.kt` | Lança DDT e inicia fluxo de automação |
| `StopBotUseCase.kt` | Para DDT e finaliza bot |
| `AutomationOrchestrator.kt` | Orquestra diferentes fluxos (login, battle, etc) |
| `MenuLoginUseCase.kt` | Valida tela de login e clica no botão |
| `ScreenValidator.kt` | Valida se screenshot corresponde ao esperado |
| `ScreenClicker.kt` | Executa click via adb com efeito visual |
| `VisionApiService.kt` | Mock da API de visão (sempre retorna 95%) |
| `AppLauncher.kt` | Abre e fecha apps externos |
| `FloatingLogWindow.kt` | Janela flutuante com logs |
| `LogFileManager.kt` | Salva logs em arquivo |

---

## 🔍 Onde os Logs Aparecem

| Tipo de Log | Local |
|-------------|-------|
| **Floating Window** | Janela sobre o jogo com scroll automático |
| **MainActivity** | `tvLog` TextView no app principal |
| **Arquivo** | `/sdcard/Download/automation-bot-ddt/logs/bot_log_*.txt` |
| **Logcat** | Via `Timber.i()`, `Timber.e()` |

---

## ✅ O que está funcionando

- ✅ Abertura do DDT via `appLauncher`
- ✅ Delay de 3s após abertura
- ✅ Validação mockada (sempre retorna 95%)
- ✅ Click na coordenada (1238, 1125)
- ✅ Logs detalhados com códigos (0009, 2929)
- ✅ Efeito visual no click
- ✅ Salvar logs em arquivo

---

## 🐛 Possíveis Problemas

### 1. **Click não está sendo executado?**
- Verifique se tem permissão para executar `adb shell input tap`
- No emulador, pode precisar habilitar opções de desenvolvedor

### 2. **Logs não aparecem?**
- Agora sim! Com a atualização, os logs devem aparecer em:
  - Floating Window
  - MainActivity (tvLog)
  - Arquivo de log

### 3. **DDT não abre?**
- Verifique se o pacote `com.road7.ddtankbr.gp` está instalado
- Use `adb shell pm list packages | grep road7` para confirmar

---

## 🚀 Próximos Passos

1. **Implementar Screenshot Real**
   - Substituir mock em `ScreenCapture.takeScreenshot()`
   - Usar MediaProjection API

2. **Criar Vision Service**
   - API Python com FastAPI
   - Template Matching com OpenCV
   - OCR com Tesseract

3. **Adicionar Mais Fluxos**
   - After login → Menu navigation
   - Battle flow
   - Resource collection

4. **Melhorar Resiliência**
   - Tratamento de erro de 5 tentativas
   - Retry automático com backoff
   - Notificação de falha via email

---

## 📊 Métricas Atuais

| Métrica | Valor |
|---------|-------|
| **Tempo total de execução** | ~7s |
| **Tempo de abertura DDT** | ~3s |
| **Tentativas de validação** | 1 (mock sempre sucede) |
| **Delay antes do click** | 1s |
| **Taxa de sucesso** | 100% (mock) |
