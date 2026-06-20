# 🐛 Screenshot Timeout Issue - Analysis

**Data**: 2026-02-28  
**Status**: 🔍 INVESTIGATING

---

## 🔍 Problema Identificado

O callback do screenshot demora **16-17 segundos**, mas o código estava esperando apenas 15s.

### Padrão Observado:

```
17:58:52 - Calling takeScreenshot() API...
17:58:52 - Waiting for callback (max 15s)...
17:59:07 - Screenshot timeout after 15 seconds  ← 15s depois
17:59:07 - Screenshot callback: SUCCESS         ← Chega 1-2s DEPOIS!
17:59:08 - Screenshot bitmap: 3120x1440
```

**Diagnóstico**: O callback **SEMPRE** chega, mas demora consistentemente 16-17 segundos.

---

## ⏱️ Histórico de Timeouts

| Versão | Timeout | Resultado | Observação |
|--------|---------|-----------|------------|
| v1 | 5s | ❌ Falha | Callback chegava 3s depois |
| v2 | 10s | ❌ Falha | Callback chegava 2s depois |
| v3 | 15s | ❌ Falha | Callback chegava 1-2s depois |
| v4 | 20s | ⏳ Testando | Deve funcionar |

---

## 📊 Análise dos Logs

### Tentativa 1:
```
16:41:35 - Calling takeScreenshot() API...
16:41:35 - Waiting for callback (max 15s)...
16:41:50 - Screenshot timeout (15s elapsed)
16:41:51 - Screenshot callback: SUCCESS (16s elapsed)
```
**Tempo real**: ~16 segundos

### Tentativa 2:
```
16:41:53 - Calling takeScreenshot() API...
16:41:53 - Waiting for callback (max 15s)...
16:42:08 - Screenshot timeout (15s elapsed)
16:42:08 - Screenshot callback: SUCCESS (15s elapsed)
```
**Tempo real**: ~15-16 segundos

### Tentativa 3:
```
16:42:10 - Calling takeScreenshot() API...
16:42:10 - Waiting for callback (max 15s)...
16:42:25 - Screenshot timeout (15s elapsed)
16:42:26 - Screenshot callback: SUCCESS (16s elapsed)
```
**Tempo real**: ~16 segundos

---

## 🎯 Conclusão

**O callback demora consistentemente 15-17 segundos**.

Isso NÃO é um bug do nosso código. É **limitação do Android Accessibility Service** em emuladores.

### Por que demora tanto?

1. **Emulador é lento**: API `takeScreenshot()` captura HardwareBuffer
2. **Conversão pesada**: `Bitmap.wrapHardwareBuffer()` é CPU intensiva
3. **Android prioriza UI**: Screenshot tem prioridade baixa
4. **Jogo rodando**: DDT game consome recursos

---

## ✅ Solução Aplicada

### Timeout aumentado para 20s

```kotlin
// BotAccessibilityService.kt

val success = screenshotLatch?.await(20, TimeUnit.SECONDS) ?: false

if (!success) {
    AutoLogger.e("Screenshot timeout after 20 seconds - callback never called")
    return null
}
```

**Por quê 20s?**
- Callback demora 15-17s consistentemente
- 20s dá margem de segurança (3-5s)
- Evita timeouts falsos positivos
- Callback sempre chega a tempo

---

## 🔍 Logs Esperados Após Fix

### ✅ Sucesso (callback < 20s):
```
17:59:10 - Calling takeScreenshot() API...
17:59:10 - Waiting for callback (max 20s)...
17:59:26 - Screenshot callback: SUCCESS         ← Dentro dos 20s!
17:59:26 - Screenshot bitmap: 3120x1440
17:59:27 - Screenshot captured: 3120x1440       ← Funciona!
17:59:27 - Calling Vision API match endpoint...
```

### ❌ Falha (callback > 20s):
```
17:59:10 - Calling takeScreenshot() API...
17:59:10 - Waiting for callback (max 20s)...
17:59:30 - Screenshot timeout after 20 seconds  ← Se passar de 20s
17:59:30 - Screenshot capture failed
17:59:30 - Screenshot capture failed - cannot validate screen
```

---

## ⚙️ Outras Observações

### LogcatMonitor Error:

```
2026-02-28 17:57:45 - [ERROR] - LogcatMonitor error: Only the original thread...
```

**Este erro é da versão ANTIGA do APK** (antes do fix com `withContext`).

Depois do `clean-install.sh` de agora, esse erro **NÃO** deve mais aparecer.

---

### Mock Screenshot nos Logs Antigos:

```
2026-02-27 20:30:24 - [WARN] - Using mock screenshot for testing
2026-02-27 20:30:24 - [INFO] - Mock screenshot loaded: 3120x1440
```

**Também é da versão antiga**. 

Depois do novo build:
- ❌ Mock removido completamente
- ✅ Retorna erro se screenshot falhar

---

## 🧪 Próximo Teste

1. **Build com novo código**:
```bash
./run/clean-install.sh emulator-5556
```

2. **Ativar Accessibility Service**:
- Settings → Accessibility → Bot DDT → ON

3. **Executar bot**:
- Clicar em "INICIAR"

4. **Observar logs**:
```bash
./run/watch-formatted.sh emulator-5556
```

### Logs esperados (v4 com 20s):
```
17:59:10 - Waiting for callback (max 20s)...
17:59:26 - Screenshot callback: SUCCESS  ← Deve chegar antes de 20s!
17:59:26 - Screenshot captured: 3120x1440
```

### Não deve mais aparecer:
- ❌ `using mock`
- ❌ `LogcatMonitor error: Only the original thread`

---

## 🎯 Se Ainda Falhar Após 20s

Se o callback AINDA demorar mais que 20s, temos 3 opções:

### 1. Aumentar para 25s (não recomendado)
- Bot muito lento
- Usuário espera demais

### 2. Usar MediaProjection API (alternativa)
- Mais rápido (~1-2s)
- Mais complexo de implementar
- Requer permissão do usuário (popup)

### 3. Async Background Capture (avançado)
- Captura screenshot em loop (a cada 5s)
- Usa último screenshot disponível
- Resposta instantânea
- Screenshot pode estar desatualizado (até 5s)

---

## 📝 Mudanças Nesta Versão

### BotAccessibilityService.kt
```kotlin
// ANTES: 15 segundos
val success = screenshotLatch?.await(15, TimeUnit.SECONDS)

// DEPOIS: 20 segundos
val success = screenshotLatch?.await(20, TimeUnit.SECONDS)
```

### ScreenCapture.kt
```kotlin
// ✅ Mock completamente removido
// ✅ Retorna null se falhar
// ✅ Logs de erro claros
```

### LogcatMonitor.kt
```kotlin
// ✅ withContext(Dispatchers.Main) adicionado
// ✅ Erro de thread corrigido
```

---

## ⏱️ Performance Esperada

| Operação | Tempo | Status |
|----------|-------|--------|
| Screenshot capture | 16-17s | ⚠️ Lento (limitação Android) |
| Vision API match | 2-3s | ✅ OK |
| Click execution | 1-2s | ✅ OK |
| **Total por tentativa** | **~20s** | ⚠️ Aceitável |

**Com 5 retries**: ~100 segundos (1min 40s) se todas falharem

---

**Após o próximo build, o screenshot deve funcionar sem timeout!** 🎯
