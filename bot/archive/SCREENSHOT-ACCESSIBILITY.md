# 📸 Screenshot via Accessibility Service - Implementado

**Data**: 2026-02-27  
**Objetivo**: Capturar screenshot real da tela do jogo

---

## ✅ O que foi implementado

### **1. BotAccessibilityService**
Adicionado método `captureScreenshot()`:
- Usa `takeScreenshot()` nativo do Android 11+ (API 30+)
- Timeout de 5 segundos
- Callback para resultado assíncrono
- Fallback para mock se falhar

### **2. ScreenCapture**
Atualizado para tentar captura real primeiro:
1. Tenta Accessibility Service (Android 11+)
2. Se falhar ou API < 30, usa mock
3. Logs claros de cada etapa

### **3. accessibility_service_config.xml**
Adicionada capacidade:
```xml
android:canTakeScreenshot="true"
```

---

## 🎯 Como funciona agora

```kotlin
ScreenCapture.takeScreenshot()
    ↓
    ├─ Android 11+ ? 
    │   ├─ SIM → Accessibility Service disponível?
    │   │   ├─ SIM → captureScreenshot() → Bitmap real ✅
    │   │   └─ NÃO → Mock
    │   └─ NÃO → Mock
    └─ Mock (fallback)
```

---

## 📊 Logs Esperados

### **Com screenshot real (sucesso):**
```
[INFO] - Capturing screenshot via Accessibility Service...
[INFO] - Screenshot captured: 1080x2340
[INFO] - Template loaded: 200x100
[INFO] - Calling Vision API lens endpoint...
[INFO] - Vision API response: found=true, confidence=0.85
[INFO] - Match found at coordinates: (540, 1200)
```

### **Com mock (fallback):**
```
[WARN] - Accessibility Service not available, using mock
[WARN] - Using mock screenshot for testing
[INFO] - Mock screenshot loaded: 3120x1440
```

---

## ⚠️ Requisitos

### **Android Version:**
- ✅ **Android 11+ (API 30+)**: Screenshot real funcionará
- ⚠️ **Android 9-10 (API 28-29)**: Usará mock
- ❌ **Android < 9 (API < 28)**: Accessibility gestures não funcionam

### **Accessibility Service:**
- ✅ Deve estar **ativado** em Settings
- ✅ Após instalar APK, **reativar** o serviço

---

## 🧪 Como testar

### **1. Compile e instale:**
```bash
cd automation-bot-ddt
./run/clean-install.sh emulator-5556
```

### **2. IMPORTANTE - Reativar Accessibility:**
```
Settings → Accessibility → Bot DDT → 
  1. Desligar (toggle OFF)
  2. Ligar novamente (toggle ON)
```

**Por quê?** Mudamos as capacidades do serviço (`canTakeScreenshot`), então o Android precisa recarregar.

### **3. Monitorar logs:**
```bash
./run/watch-formatted.sh emulator-5556
```

### **4. Iniciar bot e observar:**
- Se vir "Capturing screenshot via Accessibility Service..." = ✅ Funcionando!
- Se vir "using mock" = ⚠️ Fallback ativo

---

## 🔍 Troubleshooting

### **Problema: "Accessibility Service not available"**
**Solução**: 
1. Ir em Settings → Accessibility
2. Desligar "Bot DDT"
3. Ligar novamente
4. Reiniciar bot

### **Problema: "Screenshot failed with result: X"**
**Possíveis causas**:
- Permissão negada
- Overlay ativo bloqueando
- Android < 11

**Solução**: Usar mock por enquanto

### **Problema: Android API < 30**
Emulador/device precisa ser Android 11+. Verificar:
```bash
adb shell getprop ro.build.version.sdk
# Deve retornar 30 ou maior
```

---

## 📝 Próximos passos

1. ✅ **Testar** com emulador Android 11+
2. ✅ **Verificar** se captura funciona
3. ✅ **Ver** coordinates reais da Vision API
4. ✅ **Comparar** screenshot real vs template pequeno

---

**Status**: ✅ Implementado, pronto para teste!
