# 🚀 Como Testar MediaProjection API

**Data**: 2026-02-28  
**Status**: Ready to Test

---

## 📋 Checklist Antes de Testar

- [ ] Vision API rodando (`python main.py` em `automation-vision-ocr`)
- [ ] Emulador rodando (`emulator-5556` ou similar)
- [ ] Código compilado (novo build)

---

## 🧪 Passo a Passo do Teste

### 1️⃣ Build e Install

```bash
cd automation-bot-ddt
./run/clean-install.sh emulator-5556
```

**Aguardar**:
```
✓ Clean install completed!

⚠️  CRITICAL: Manual steps required
```

---

### 2️⃣ Aprovar Permissões

O app vai solicitar **3 permissões**:

#### A. Overlay Permission
- Sistema abre Settings
- Ativar toggle "Permit drawing over other apps"
- Voltar ao app

**Log esperado**:
```
✅ Overlay permission: GRANTED
```

---

#### B. Accessibility Service
- Sistema abre Settings → Accessibility
- Procurar "Bot DDT"
- Ativar toggle
- Confirmar popup
- Voltar ao app

**Log esperado**:
```
✅ Accessibility service: ENABLED
```

---

#### C. Screen Capture (NOVO!) 🎯

**Log na app**:
```
❌ Screen capture permission: NOT GRANTED

⚠️ IMPORTANT: System will show a popup
You MUST click 'START NOW' to approve!
Do NOT click 'CANCEL'

Requesting screen capture permission...
```

**Sistema exibe popup**:
```
┌──────────────────────────────────────────┐
│  Start capturing everything that's       │
│  displayed on your screen?               │
│                                          │
│  Bot DDT will be able to capture all    │
│  content on your screen.                │
│                                          │
│  [CANCEL]              [START NOW]       │
└──────────────────────────────────────────┘
```

**✅ CLICAR EM "START NOW"** (NÃO clicar em CANCEL!)

**Log esperado após aprovar**:
```
✅ Screen capture permission granted!
Screenshot capture ready - Fast mode enabled!
════════════════════════════════════════
All permissions granted!
Press START to begin automation
```

---

### 3️⃣ Iniciar Bot

Clicar no botão **"START"** na MainActivity.

**Logs esperados**:
```
Opening DDT game...
DDT launched successfully
Starting login screen validation...
Waiting screenshot (101)
Capturing screenshot via MediaProjection...
Screenshot captured in 1200ms: 3120x1440  ← RÁPIDO! ✅
Calling Vision API match endpoint...
Vision API response: found=true, confidence=0.95
Screen match confirmed!
Click executed via Accessibility at (1238, 1125)
```

---

### 4️⃣ Monitorar Logs

Em outro terminal:

```bash
./run/watch-formatted.sh emulator-5556
```

**Verificar**:
- ✅ Screenshot deve demorar ~1-2s (não 15s!)
- ✅ Logs não devem mostrar "timeout"
- ✅ Deve mostrar "captured in XXXms"

---

## 🔍 Troubleshooting

### ❌ Problema: "MediaProjection not initialized"

**Causa**: Você clicou em "CANCEL" ao invés de "START NOW"

**Solução**:
1. Fechar app
2. Reabrir app
3. Popup aparece novamente
4. Clicar em "START NOW" desta vez

---

### ❌ Problema: Popup não aparece

**Causa**: Permissão pode já estar negada

**Solução**:
```bash
# Limpar permissões do app
adb -s emulator-5556 shell pm clear com.automation.bot

# Reinstalar
./run/clean-install.sh emulator-5556
```

---

### ❌ Problema: "Screenshot capture failed"

**Causa**: MediaProjection não inicializou corretamente

**Verificar logs**:
```bash
adb -s emulator-5556 logcat | grep "MediaProjection"
```

**Solução**:
```bash
# Verificar status com script diagnóstico
./run/diagnose-mediaprojection.sh emulator-5556
```

---

### ❌ Problema: LogcatMonitor error ainda aparece

**Causa**: Você ainda está com APK antigo instalado

**Logs antigos mostram**:
```
2026-02-28 16:40:37 - Capturing screenshot via Accessibility Service...
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                      Isso é do código ANTIGO!
```

**Solução**: O `clean-install.sh` que você rodou agora deve ter atualizado. Se ainda aparecer, rebuild:

```bash
./run/clean-install.sh emulator-5556
```

---

## 📊 Diferença Visual nos Logs

### ❌ ANTES (Accessibility - 16s):
```
18:00:00 - Capturing screenshot via Accessibility Service...
18:00:00 - Starting screenshot capture...
18:00:00 - Waiting for callback (max 15s)...
18:00:15 - Screenshot timeout after 15 seconds  ← Muito lento!
```

### ✅ DEPOIS (MediaProjection - 1-2s):
```
18:00:00 - Capturing screenshot via MediaProjection...
18:00:01 - Screenshot captured in 1200ms  ← Rápido! ✅
```

---

## 🎯 Como Confirmar Que Funcionou

### 1. Logs mostram "MediaProjection" (não "Accessibility Service"):
```
✅ Capturing screenshot via MediaProjection...
❌ Capturing screenshot via Accessibility Service...  (OLD)
```

### 2. Tempo de captura ~1-2s:
```
✅ Screenshot captured in 1200ms
❌ Screenshot timeout after 15 seconds  (OLD)
```

### 3. Sem erro de "not initialized":
```
❌ MediaProjection not initialized - grant permission first
```

---

## ⚠️ IMPORTANTE

### O Popup DEVE ser Aprovado!

Quando o sistema mostrar:

```
Start capturing everything that's displayed on your screen?
```

Você **DEVE** clicar em **"START NOW"** (botão da direita).

Se clicar em "CANCEL", o bot não vai funcionar!

---

## 📝 Ordem das Permissões

```
1. Overlay Permission → Manual (Settings)
2. Accessibility Service → Manual (Settings)
3. MediaProjection → Popup (Clicar "START NOW") ← NOVO!
```

Todas são necessárias para o bot funcionar.

---

## ✅ Checklist Final

Após seguir todos os passos, você deve ver:

```
✅ Overlay permission: GRANTED
✅ Accessibility service: ENABLED
✅ Screen capture permission: GRANTED
════════════════════════════════════════
All permissions granted!
Press START to begin automation
```

**Então clicar em "START" e verificar logs:**

```
Screenshot captured in 1200ms: 3120x1440  ← Sucesso!
```

---

**Pronto para testar com MediaProjection!** 🚀

Use `./run/diagnose-mediaprojection.sh emulator-5556` se tiver problemas.
