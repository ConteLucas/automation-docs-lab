# 🔗 Integração Vision API - Guia Completo

**Data**: 2026-02-27  
**Status**: Pronto para integração

---

## 📁 Arquivos Criados

### **1. `VisionApiServiceReal.kt`** (Novo)
Implementação real da Vision API usando Retrofit.

**Localização**: `app/src/main/java/com/automation/bot/api/VisionApiServiceReal.kt`

**Endpoints implementados:**
- ✅ `/api/v1/vision/lens` - Localizar objeto em tela
- ✅ `/api/v1/ocr/extract` - Extrair texto
- ✅ `/api/v1/ocr/extract-number` - Extrair apenas números
- ✅ `/health` - Health check

### **2. `VisionApiService.kt`** (Antigo - Mock)
Mantido para referência, mas será substituído.

---

## 🔄 Próximos Passos

### **Opção 1: Substituir completamente (Recomendado)**

```bash
# 1. Deletar arquivo mock
rm app/src/main/java/com/automation/bot/api/VisionApiService.kt

# 2. Renomear arquivo real
mv app/src/main/java/com/automation/bot/api/VisionApiServiceReal.kt \
   app/src/main/java/com/automation/bot/api/VisionApiService.kt
```

### **Opção 2: Manter ambos e escolher**

Criar um `flag` ou `BuildConfig` para escolher entre mock e real.

---

## 🚀 Como Usar

### **No ScreenValidator**

Atualmente o `ScreenValidator` chama:
```kotlin
val response = visionApi.matchTemplate(
    screenshot = screenshotBytes,
    templateName = expectedScreen.templatePath,
    threshold = minConfidence
)
```

**Problema**: Esse método não existe na versão real!

**Solução**: Atualizar `ScreenValidator` para usar o novo método `lens()`:

```kotlin
// OLD (mock):
val response = visionApi.matchTemplate(screenshot, templateName, threshold)

// NEW (real):
val templateBitmap = templateManager.loadTemplateAsBitmap(expectedScreen.templatePath)
val screenshotBitmap = screenshot  // já é Bitmap

val lensResult = visionApi.lens(
    objectImage = templateBitmap,    // Template pequeno
    screenImage = screenshotBitmap,  // Screenshot inteiro
    threshold = minConfidence
)

// lensResult contém:
// - found: Boolean
// - confidence: Float
// - x, y: Coordenadas onde encontrou
// - width, height: Tamanho do objeto
```

---

## 🛠️ Mudanças Necessárias

### **1. Atualizar `ScreenValidator.kt`**

<details>
<summary>Ver código atualizado</summary>

```kotlin
suspend fun validateScreen(expectedScreen: GameScreen): ScreenMatch {
    Timber.i("[INFO] Validating screen: ${expectedScreen.description}")
    
    try {
        // 1. Capturar screenshot da tela inteira
        val screenshot = screenCapture.takeScreenshot()
        if (screenshot == null) {
            Timber.w("[WARN] Failed to capture screenshot")
            return ScreenMatch(false, 0f, expectedScreen)
        }
        
        // 2. Carregar template (objeto a procurar)
        val templateBitmap = templateManager.loadTemplateAsBitmap(expectedScreen.templatePath)
        if (templateBitmap == null) {
            Timber.w("[WARN] Template not found: ${expectedScreen.templatePath}")
            return ScreenMatch(false, 0f, expectedScreen)
        }
        
        // 3. Usar Vision API (lens) para encontrar template no screenshot
        val lensResult = visionApi.lens(
            objectImage = templateBitmap,
            screenImage = screenshot,
            threshold = minConfidence
        )
        
        Timber.i("[INFO] Vision API lens: found=${lensResult.found}, confidence=${lensResult.confidence}")
        
        // 4. Retornar resultado
        return ScreenMatch(
            isMatch = lensResult.found && lensResult.confidence >= minConfidence,
            confidence = lensResult.confidence,
            expectedScreen = expectedScreen,
            coordinates = if (lensResult.found) {
                Pair(lensResult.x + lensResult.width/2, lensResult.y + lensResult.height/2)
            } else null
        )
        
    } catch (e: Exception) {
        Timber.e(e, "[ERROR] Failed to validate screen")
        return ScreenMatch(false, 0f, expectedScreen)
    }
}
```

</details>

### **2. Atualizar `TemplateManager.kt`**

Adicionar método para carregar template como `Bitmap`:

```kotlin
fun loadTemplateAsBitmap(templatePath: String): Bitmap? {
    return try {
        val inputStream = context.assets.open(templatePath)
        BitmapFactory.decodeStream(inputStream)
    } catch (e: Exception) {
        Timber.e(e, "Failed to load template: $templatePath")
        null
    }
}
```

### **3. Atualizar `ScreenMatch.kt`**

Adicionar campo opcional para coordenadas:

```kotlin
data class ScreenMatch(
    val isMatch: Boolean,
    val confidence: Float,
    val expectedScreen: GameScreen,
    val coordinates: Pair<Int, Int>? = null  // (x, y) do centro do objeto
)
```

---

## 🧪 Como Testar

### **1. Iniciar Vision API**
```bash
cd automation-vision-ocr
./start-vision-api.sh
```

### **2. Verificar conectividade**
```bash
# Do Mac
curl http://localhost:8000/health

# Do emulador (simular)
curl http://10.0.2.2:8000/health
```

### **3. Instalar Bot no emulador**
```bash
cd automation-bot-ddt/run
./run.sh emulator-5554
```

### **4. Testar no app**
1. Abrir o Bot DDT no emulador
2. Clicar em **INICIAR**
3. Bot vai capturar screenshot
4. Enviar para Vision API
5. Vision API retorna coordenadas
6. Bot clica nas coordenadas

---

## 📊 Fluxo Completo

```
User clicks INICIAR
    ↓
MenuLoginUseCase.execute()
    ↓
ScreenValidator.validateScreen(LOGIN_SCREEN)
    ↓
1. ScreenCapture.takeScreenshot() → Bitmap (1440x2560)
2. TemplateManager.loadTemplate("login-button.png") → Bitmap (200x80)
3. VisionApiService.lens(template, screenshot)
    ↓
    HTTP POST http://10.0.2.2:8000/api/v1/vision/lens
    {
      "object_image": "base64...",
      "screen_image": "base64..."
    }
    ↓
    Vision API (Python/OpenCV) processa
    ↓
    Response: { "found": true, "x": 640, "y": 1200, ... }
    ↓
4. ScreenMatch(found=true, coords=(640, 1200))
    ↓
5. ScreenClicker.clickAt(640, 1200)
    ↓
✅ Click executado!
```

---

## ⚠️ Troubleshooting

### **Vision API não responde**
```bash
# Verificar se Colima está rodando
colima status

# Verificar se container está rodando
docker ps | grep ddt-vision-api

# Ver logs
docker logs -f ddt-vision-api
```

### **Bot não consegue conectar**
```bash
# Do emulador, testar conectividade
adb -s emulator-5554 shell ping -c 3 10.0.2.2

# Verificar porta
curl http://10.0.2.2:8000/health
```

### **Erro de timeout**
- Aumentar timeout no `OkHttpClient` (já está em 30s)
- Verificar se Vision API está respondendo rápido (`docker logs`)

---

## ✅ Checklist de Integração

- [ ] Deletar/renomear `VisionApiService.kt` (mock)
- [ ] Atualizar `ScreenValidator.kt` para usar `lens()`
- [ ] Adicionar `loadTemplateAsBitmap()` no `TemplateManager`
- [ ] Atualizar `ScreenMatch` com campo `coordinates`
- [ ] Iniciar Vision API com Colima
- [ ] Testar conectividade (curl)
- [ ] Build e instalar bot
- [ ] Testar fluxo completo

---

**Status**: 🚧 Pronto para integração  
**Próximo**: Aplicar mudanças no código Android
