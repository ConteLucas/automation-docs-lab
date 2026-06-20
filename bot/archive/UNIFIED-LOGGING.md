# 📝 Logs Unificados - AutoLogger

**Data**: 2026-02-27  
**Objetivo**: Garantir que TODOS os logs apareçam em Logcat, Float, MainActivity e Arquivo

---

## 🎯 Problema Resolvido

Antes: Logs estavam espalhados e inconsistentes
- `Timber.i()` → Apenas logcat
- `onLog?.invoke()` → Float + MainActivity
- `logFileManager.appendLog()` → Arquivo

**Agora**: Um único ponto para todos os logs!

---

## 🔧 Como Usar o AutoLogger

### **1. Substitua Timber por AutoLogger**

**ANTES:**
```kotlin
Timber.i("[INFO] Bot started")
onLog?.invoke("[INFO] Bot started")
```

**DEPOIS:**
```kotlin
AutoLogger.i("Bot started")
// Vai automaticamente para: Logcat + Float + MainActivity + Arquivo!
```

### **2. Níveis de Log**

```kotlin
// INFO - Informação geral
AutoLogger.i("Bot started")
AutoLogger.i("Screen matched (101) - confidence: 95.00%")

// WARN - Avisos
AutoLogger.w("Click failed on attempt 1")
AutoLogger.w("Accessibility service not available")

// ERROR - Erros
AutoLogger.e("Failed to click login button")
AutoLogger.e("Vision API error", exception)  // Com exception

// DEBUG - Debug (apenas development)
AutoLogger.d("Variable value: $value")
```

---

## 📋 Arquivos a Atualizar

### **1. ScreenClicker.kt**

**ANTES:**
```kotlin
val startLog = "[INFO] Executing click at ($x, $y)"
Timber.i(startLog)
onLog?.invoke(startLog)
```

**DEPOIS:**
```kotlin
AutoLogger.i("Executing click at ($x, $y)")
```

### **2. MenuLoginUseCase.kt**

**ANTES:**
```kotlin
val startLog = "[INFO] Starting login screen validation..."
Timber.i(startLog)
onLog?.invoke(startLog)
```

**DEPOIS:**
```kotlin
AutoLogger.i("Starting login screen validation...")
```

### **3. ScreenValidator.kt**

**ANTES:**
```kotlin
Timber.i("[INFO] Validating screen: ${expectedScreen.description}")
```

**DEPOIS:**
```kotlin
AutoLogger.i("Validating screen: ${expectedScreen.description}")
```

### **4. StartBotUseCase.kt**

**ANTES:**
```kotlin
val launchLog = "Opening DDT game (${AppConstants.DDT_PACKAGE_NAME})"
Timber.i(launchLog)
onLog?.invoke(launchLog)
```

**DEPOIS:**
```kotlin
AutoLogger.i("Opening DDT game (${AppConstants.DDT_PACKAGE_NAME})")
```

---

## ✅ Benefícios

1. **Consistência**: Todos os logs no mesmo formato
2. **Simplicidade**: Uma chamada faz tudo
3. **Rastreabilidade**: Timestamp automático
4. **Centralizado**: Fácil adicionar novos destinos (ex: enviar para servidor)
5. **Menos código**: Menos linhas repetidas

---

## 🔍 Exemplo de Log Gerado

```
2026-02-27 16:30:45 - [INFO] - Bot started
2026-02-27 16:30:46 - [INFO] - Opening DDT game (com.road7.ddtankbr.gp)
2026-02-27 16:30:48 - [INFO] - Starting login screen validation...
2026-02-27 16:30:49 - [INFO] - Screen matched (101) - confidence: 95.00%
2026-02-27 16:30:55 - [INFO] - Executing click at (1238, 1125)
2026-02-27 16:30:56 - [INFO] - Click executed via Accessibility at (1238, 1125)
```

**Esse mesmo log aparece:**
- ✅ No `./watch-bot-only.sh` (logcat)
- ✅ Na floating window
- ✅ Na MainActivity
- ✅ No arquivo `/sdcard/Download/automation-bot-ddt/logs/...`

---

## 🚀 Migração Rápida

### **Script de busca e substituição:**

```bash
# Encontrar todos os usos de Timber + onLog
cd automation-bot-ddt
grep -r "Timber\." app/src/main/java/com/automation/bot/
```

### **Padrões a substituir:**

1. **Timber.i + onLog**
```kotlin
// BUSCAR:
val logMessage = "[INFO] Something"
Timber.i(logMessage)
onLog?.invoke(logMessage)

// SUBSTITUIR POR:
AutoLogger.i("Something")
```

2. **Apenas Timber**
```kotlin
// BUSCAR:
Timber.i("[INFO] Something")

// SUBSTITUIR POR:
AutoLogger.i("Something")
```

3. **Timber.e com exception**
```kotlin
// BUSCAR:
Timber.e(exception, "[ERROR] Something")

// SUBSTITUIR POR:
AutoLogger.e("Something", exception)
```

---

## ⚠️ Notas Importantes

1. **Não adicione [INFO], [WARN], [ERROR]** manualmente - AutoLogger adiciona automaticamente
2. **AutoLogger já adiciona timestamp** - não precisa adicionar manualmente
3. **Inicialização já feita** no `BotFactory` - não precisa inicializar novamente
4. **onLog pode ser removido** dos parâmetros dos UseCases (depois da migração completa)

---

## 📊 Status da Migração

- [ ] ScreenClicker.kt
- [ ] MenuLoginUseCase.kt
- [ ] ScreenValidator.kt
- [ ] StartBotUseCase.kt
- [ ] StopBotUseCase.kt
- [ ] AutomationOrchestrator.kt
- [ ] BotAccessibilityService.kt
- [ ] MainActivity.kt

---

**Vantagem**: Depois da migração, você verá **exatamente os mesmos logs** no `./watch-bot-only.sh`, no float e no app! 🎯
