# VISION API MOCK

## 📋 Visão Geral

O `VisionApiService` atualmente é um **mock** que simula a resposta de um serviço real de visão computacional.

---

## 🎯 Comportamento do Mock

### 1️⃣ Template Matching (`matchTemplate`)

**O que faz:**
- Simula validação de imagem (comparação de screenshot com template)
- Sempre retorna **match = true**
- Confidence varia aleatoriamente entre **90-98%**

**Por que assim:**
- Para desenvolvimento inicial, não precisamos de processamento real de imagem
- Permite testar toda a lógica de fluxo sem depender da Vision API real
- As **coordenadas do click são gerenciadas pelo enum `GameCoordinate`**, não pelo Vision

```kotlin
suspend fun matchTemplate(
    screenshot: ByteArray,
    templateName: String,
    threshold: Float = 0.8f
): MatchResult {
    delay(200)  // Simula latência de rede
    
    val mockConfidence = (90..98).random() / 100f  // 0.90 - 0.98
    
    return MatchResult(
        match = true,
        confidence = mockConfidence
    )
}
```

**Exemplo de retorno:**
```kotlin
MatchResult(
    match = true,
    confidence = 0.95f  // 95%
)
```

---

### 2️⃣ OCR (`extractText`)

**O que faz:**
- Simula extração de texto de imagem (OCR - Optical Character Recognition)
- Sempre retorna **"50"** (level hardcoded)
- Confidence varia aleatoriamente entre **90-95%**

**Por que assim:**
- Para desenvolvimento, não precisamos de OCR real
- Permite testar o fluxo de captura de nível do jogador
- Futuramente, será substituído por Tesseract real

```kotlin
suspend fun extractText(
    screenshot: ByteArray,
    region: Region? = null
): OcrResult {
    delay(300)  // Simula latência de processamento OCR
    
    val mockConfidence = (90..95).random() / 100f  // 0.90 - 0.95
    
    return OcrResult(
        text = "50",
        confidence = mockConfidence
    )
}
```

**Exemplo de retorno:**
```kotlin
OcrResult(
    text = "50",
    confidence = 0.92f  // 92%
)
```

---

## 📦 Data Classes

### `MatchResult`

Resultado da comparação de imagens.

```kotlin
data class MatchResult(
    val match: Boolean,      // True = imagem encontrada
    val confidence: Float    // 0.0 - 1.0 (ex: 0.95 = 95%)
)
```

**Importante:** 
- ❌ **Não retorna coordenadas** (foram removidas)
- ✅ As coordenadas de click vêm do `GameCoordinate` enum

---

### `Region`

Define uma área retangular dentro de uma imagem (para OCR focado).

```kotlin
data class Region(
    val x: Int,        // Posição X inicial
    val y: Int,        // Posição Y inicial
    val width: Int,    // Largura
    val height: Int    // Altura
)
```

**Exemplo de uso futuro:**
```kotlin
// Extrair texto apenas da área do nível
val levelRegion = Region(x=100, y=50, width=200, height=40)
val result = visionApi.extractText(screenshot, levelRegion)
```

---

### `OcrResult`

Resultado da extração de texto.

```kotlin
data class OcrResult(
    val text: String,        // Texto extraído
    val confidence: Float    // 0.0 - 1.0 (ex: 0.92 = 92%)
)
```

---

## 🔄 Fluxo de Uso Atual

```
┌─────────────────────┐
│ MenuLoginUseCase    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ ScreenValidator     │ 1. Take screenshot (mock)
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ VisionApiService    │ 2. matchTemplate()
│ (MOCK)              │    → match: true
└──────────┬──────────┘    → confidence: 95%
           │
           ▼
┌─────────────────────┐
│ ScreenMatch         │ 3. Return result
│ isMatch: true       │    (no coordinates)
│ confidence: 0.95    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ ScreenClicker       │ 4. Click using
│                     │    GameCoordinate.LOGIN_BTN_ENTER
│                     │    → (1238, 1125)
└─────────────────────┘
```

---

## 🚀 Migração para Vision Real (Futuro)

Quando implementarmos a Vision API real:

### 1️⃣ Criar Microservice Python

```python
# automation-vision-ocr/app/main.py
from fastapi import FastAPI, UploadFile
import cv2
import numpy as np

@app.post("/api/v1/match-template")
async def match_template(
    screenshot: UploadFile,
    template_name: str,
    threshold: float = 0.8
):
    # 1. Load images
    screenshot_img = cv2.imdecode(...)
    template_img = cv2.imread(f"templates/{template_name}")
    
    # 2. Template Matching
    result = cv2.matchTemplate(screenshot_img, template_img, cv2.TM_CCOEFF_NORMED)
    min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)
    
    # 3. Return result
    return {
        "match": max_val >= threshold,
        "confidence": float(max_val)
    }
```

### 2️⃣ Substituir Mock por Retrofit

```kotlin
// VisionApiService.kt (REAL)
interface VisionApiService {
    @Multipart
    @POST("/api/v1/match-template")
    suspend fun matchTemplate(
        @Part screenshot: MultipartBody.Part,
        @Part("template_name") templateName: RequestBody,
        @Part("threshold") threshold: RequestBody
    ): MatchResult
}
```

### 3️⃣ Configurar Retrofit

```kotlin
// BotFactory.kt
val retrofit = Retrofit.Builder()
    .baseUrl("http://192.168.1.100:8000")  // IP do servidor Vision
    .addConverterFactory(GsonConverterFactory.create())
    .build()

val visionApi = retrofit.create(VisionApiService::class.java)
```

---

## ✅ Vantagens do Mock Atual

| Vantagem | Descrição |
|----------|-----------|
| **Rápido** | Não depende de processamento pesado |
| **Simples** | Fácil de testar e debugar |
| **Independente** | Não requer servidor externo |
| **Previsível** | Sempre retorna sucesso (bom para testar fluxo) |
| **Zero custo** | Não usa recursos de computação |

---

## 🎯 Threshold (Limiar de Confiança)

O threshold define o **mínimo de confiança** necessário para considerar um match válido.

**Configuração atual:**
```kotlin
// AppConstants.kt
const val MIN_CONFIDENCE_THRESHOLD = 0.9f  // 90%
```

**Como funciona:**
```kotlin
// ScreenValidator.kt
return ScreenMatch(
    isMatch = response.match && response.confidence >= minConfidence,
    confidence = response.confidence,
    expectedScreen = expectedScreen
)
```

**Exemplo:**
- Vision retorna `confidence = 0.95` (95%)
- Threshold é `0.9` (90%)
- Resultado: `isMatch = true` ✅

---

## 📊 Logs de Exemplo

```
[11:30:45] Starting login screen validation...
[11:30:45] Waiting screenshot menu page (0009)
[11:30:45] Attempt 1/5 for screen (0009)
[11:30:45] Vision API response: match=true, confidence=0.95
[11:30:45] Screen matched (0009) - confidence: 95.00%
[11:30:45] Waiting 1000ms before click...
[11:30:46] Click coordinate (2929) at X:1238 Y:1125
[11:30:46] Executing click at (1238, 1125)
```

---

## 🐛 Troubleshooting

### Mock sempre retorna `true` - é normal?

✅ **Sim!** O mock foi projetado para sempre retornar sucesso. Quando implementarmos a Vision API real, ela retornará `match: false` quando a imagem não for encontrada.

### Por que não retorna coordenadas?

As coordenadas do Vision Service são úteis para **detectar onde uma imagem apareceu**, mas no nosso caso:
- Já sabemos **exatamente onde clicar** (via `GameCoordinate` enum)
- Só precisamos **validar se a tela é a correta** (login, battle, etc)
- Simplifica o mock e o fluxo

### Como testar falha?

Para testar falha de validação, você pode temporariamente modificar o mock:

```kotlin
// Para testar falha
return MatchResult(
    match = false,  // ❌ Força falha
    confidence = 0.5f
)
```

---

## 📝 Checklist de Implementação Real

Quando estiver pronto para implementar a Vision API real:

- [ ] Criar microservice Python (`automation-vision-ocr`)
- [ ] Implementar Template Matching com OpenCV
- [ ] Implementar OCR com Tesseract
- [ ] Adicionar templates em `assets/templates/ddt/`
- [ ] Configurar Retrofit no Android
- [ ] Substituir mock por implementação real
- [ ] Testar com diferentes condições de iluminação
- [ ] Ajustar threshold se necessário
- [ ] Implementar cache de templates
- [ ] Adicionar retry automático em caso de falha de rede
