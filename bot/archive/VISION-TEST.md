# 🧪 Vision API Integration Test

**Data**: 2026-02-27  
**Objetivo**: Testar integração real entre Bot Android e Vision API

---

## 📋 Pré-requisitos

### 1. Vision API Rodando
```bash
cd automation-vision-ocr
./start-vision-api.sh
```

Verificar se está rodando:
```bash
curl http://localhost:8000/health
# Deve retornar: {"status":"healthy","service":"DDT Vision API"}
```

### 2. Template de Login
Verificar se existe o arquivo:
```
automation-bot-ddt/app/src/main/assets/templates/ddt/login/options-login.png
```

### 3. Bot Android Compilado
```bash
cd automation-bot-ddt
./run/run.sh
```

---

## 🔄 Fluxo do Teste

### **O que vai acontecer:**

1. **Bot abre o jogo DDT** (`StartBotUseCase`)
2. **Bot chama `MenuLoginUseCase.execute()`**
3. **`MenuLoginUseCase` chama `ScreenValidator.validateScreenWithRetry()`**
4. **`ScreenValidator` faz:**
   - Captura screenshot da tela atual (via `ScreenCapture.takeScreenshot()`)
   - Carrega template `ddt/login/options-login.png` (via `TemplateManager.loadTemplateAsBitmap()`)
   - Envia ambos para Vision API (`/api/v1/vision/lens`)
5. **Vision API retorna:**
   ```json
   {
     "found": true,
     "confidence": 0.95,
     "x": 640,
     "y": 360,
     "width": 200,
     "height": 100
   }
   ```
6. **Bot valida resultado:**
   - Se `found == true` e `confidence >= 0.8`: ✅ Tela detectada
   - Se não: ❌ Tela não encontrada, retry

---

## 🧩 Arquitetura da Integração

```
┌─────────────────────────────────────────────────────────────┐
│                     MenuLoginUseCase                        │
│  - execute() → Inicia validação de tela de login           │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    ScreenValidator                          │
│  - validateScreenWithRetry() → Tenta até 5x                │
│  - validateScreen() → Valida 1 vez                          │
└─────────────┬───────────────────────────────────────────────┘
              │
              ├──► ScreenCapture.takeScreenshot() → Bitmap
              │
              ├──► TemplateManager.loadTemplateAsBitmap() → Bitmap
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│                   VisionApiService                          │
│  - lens(objectImage, screenImage, threshold)                │
│  - Converte Bitmap → Base64                                 │
│  - POST /api/v1/vision/lens                                 │
└─────────────┬───────────────────────────────────────────────┘
              │
              │ HTTP Request (JSON)
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│              Vision API (Python/FastAPI)                    │
│  - Recebe object_image (base64) + screen_image (base64)    │
│  - Decodifica ambas as imagens                              │
│  - OpenCV Template Matching                                 │
│  - Retorna: found, confidence, x, y, width, height          │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Expected Logs

### **No Float e Logcat:**

```
2026-02-27 18:00:00 - [INFO] - Bot started
2026-02-27 18:00:01 - [INFO] - Opening DDT game (com.road7.ddtankbr.gp)
2026-02-27 18:00:03 - [INFO] - Starting login screen validation...
2026-02-27 18:00:03 - [INFO] - Waiting screenshot (101)
2026-02-27 18:00:03 - [INFO] - Attempt 1/5 for screen (101)
2026-02-27 18:00:03 - [INFO] - Validating screen: Main login screen
2026-02-27 18:00:04 - [INFO] - Vision API response: found=true, confidence=0.95
2026-02-27 18:00:04 - [INFO] - Screen matched (101) - confidence: 95.00%
2026-02-27 18:00:04 - [INFO] - Login screen detected! Confidence: 95.00%
2026-02-27 18:00:04 - [INFO] - Waiting for screen to fully load...
2026-02-27 18:00:07 - [INFO] - 7 seconds remaining...
2026-02-27 18:00:10 - [INFO] - 4 seconds remaining...
2026-02-27 18:00:14 - [INFO] - Screen should be fully loaded now
2026-02-27 18:00:14 - [INFO] - Executing click at (1238, 1125)
2026-02-27 18:00:15 - [INFO] - Click executed via Accessibility at (1238, 1125)
```

### **Se Vision API falhar:**

```
2026-02-27 18:00:03 - [WARN] - Failed to capture screenshot - using mock
2026-02-27 18:00:04 - [INFO] - Screen matched (101) - confidence: 100.00%
```

### **Se template não existir:**

```
2026-02-27 18:00:03 - [WARN] - Template not found: ddt/login/options-login.png - using mock
```

### **Se Vision API retornar erro:**

```
2026-02-27 18:00:04 - [ERROR] - Vision API error: Failed to decode image
```

---

## 🚨 Problemas Conhecidos

### **1. `ScreenCapture.takeScreenshot()` retorna `null`**

**Causa**: Método ainda não implementado (retorna `null` por padrão)

**Solução Temporária**: O código vai usar mock (`createMockMatch()`) e continuar funcionando

**Solução Real**: Implementar captura de screenshot via Accessibility Service

---

### **2. Vision API não alcançável do emulador**

**Sintomas**:
```
[ERROR] Failed to validate screen
java.net.ConnectException: Failed to connect to /10.0.2.2:8000
```

**Causa**: Vision API não está rodando ou Colima está parado

**Solução**:
```bash
# Verificar se Colima está rodando
colima status

# Verificar se Vision API está rodando
docker ps | grep ddt-vision-api

# Reiniciar se necessário
cd automation-vision-ocr
./start-vision-api.sh
```

---

### **3. Template não encontrado**

**Sintomas**:
```
[WARN] Template not found: ddt/login/options-login.png - using mock
```

**Causa**: Arquivo não existe em `assets/templates/`

**Solução**:
```bash
# Verificar se template existe
ls -la automation-bot-ddt/app/src/main/assets/templates/ddt/login/

# Adicionar template se necessário
# cp sua_imagem.png automation-bot-ddt/app/src/main/assets/templates/ddt/login/options-login.png
```

---

## 🔧 Debugging

### **Ver logs da Vision API:**

```bash
docker logs -f ddt-vision-api
```

### **Testar Vision API manualmente (curl):**

```bash
# Health check
curl http://localhost:8000/health

# Lens endpoint (exemplo com base64 fake)
curl -X POST http://localhost:8000/api/v1/vision/lens \
  -H "Content-Type: application/json" \
  -d '{
    "object_image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
    "screen_image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
    "threshold": 0.8
  }'
```

### **Ver logs do Bot:**

```bash
cd automation-bot-ddt
./run/watch-bot-only.sh
```

---

## ✅ Checklist de Teste

- [ ] Vision API está rodando (`docker ps`)
- [ ] Template existe (`ls assets/templates/ddt/login/`)
- [ ] Bot compila sem erros (`./run/run.sh`)
- [ ] Emulador está rodando
- [ ] Jogo DDT está instalado no emulador
- [ ] Accessibility Service está ativado
- [ ] Logs aparecem no float e logcat
- [ ] Vision API recebe requests (ver `docker logs -f ddt-vision-api`)

---

## 🎯 Próximos Passos

1. **Implementar `ScreenCapture.takeScreenshot()`** usando Accessibility Service
2. **Capturar screenshots reais** para validar o Vision API
3. **Adicionar mais templates** (botões, telas, etc)
4. **Ajustar threshold** de confiança conforme necessário
5. **Testar com telas reais** do jogo DDT

---

**Status Atual**: 
- ✅ Vision API implementado e funcionando
- ✅ `ScreenValidator` integrado com Vision API
- ✅ DTOs e arquitetura limpa
- ⚠️ `ScreenCapture` retorna `null` (mock ativo)
- ⚠️ Teste real depende de screenshot funcional
