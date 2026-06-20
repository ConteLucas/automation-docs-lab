# 🔍 Vision API Guide

Complete guide for the Vision API integration and template matching system.

## 🎯 Overview

The Vision API analyzes screenshots to detect UI elements using OpenCV template matching.

### What It Does

- 🔍 **Locate elements**: Find buttons, text, UI components
- 📊 **High precision**: 93%+ accuracy with dual-method validation
- 🚫 **Reject false positives**: <1% error rate
- ⚡ **Fast**: <1s response time

## 🏗️ Architecture

```
Android App (Kotlin)
    ↓ Screenshot (Base64)
Vision API (Python/FastAPI)
    ↓ OpenCV Analysis
Result (coordinates, confidence)
    ↓
Android App (Dynamic Click)
```

### Components

**Android Side:**
- `VisionApiService.kt` - Retrofit client
- `ScreenValidator.kt` - Validation logic
- Template images in `assets/templates/`

**Python Side:**
- `vision_routes.py` - FastAPI endpoints
- `vision_service.py` - OpenCV logic
- Docker container for deployment

## 🚀 Endpoints

### 1️⃣ `/lens` - Locate Element

Find a small element (button, icon) within a larger screenshot.

**Request:**
```json
{
  "object_image": "base64...",
  "screen_image": "base64...",
  "threshold": 0.90
}
```

**Response:**
```json
{
  "found": true,
  "confidence": 0.9312,
  "x": 66,
  "y": 446,
  "width": 356,
  "height": 101
}
```

**When to Use:** Detecting specific buttons, icons, UI elements

### 2️⃣ `/match` - Compare Screens

Compare two full screenshots for similarity.

**Request:**
```json
{
  "object_image": "base64...",
  "screen_image": "base64...",
  "threshold": 0.85
}
```

**Response:**
```json
{
  "found": true,
  "confidence": 0.9015,
  "x": 0,
  "y": 0,
  "width": 1280,
  "height": 720
}
```

**When to Use:** Verifying if two screens are the same (e.g., loading screens)

### 3️⃣ `/ocr` - Extract Text

Extract text from image region using Tesseract OCR.

**Request:**
```json
{
  "image": "base64...",
  "language": "eng"
}
```

**Response:**
```json
{
  "text": "Level 42",
  "confidence": 0.95
}
```

**When to Use:** Reading text from screenshots (levels, stats, etc.)

### 4️⃣ `/health` - Health Check

```json
GET /health
→ {"status": "healthy"}
```

## 🔧 Configuration

### Confidence Thresholds

```kotlin
// AppConstants.kt
const val MIN_CONFIDENCE_THRESHOLD = 0.90f  // 90% for lens
```

**Recommended Values:**
- `lens` (element): 0.85 - 0.95 (90% default)
- `match` (full screen): 0.80 - 0.90 (85% default)
- `ocr` (text): 0.70 - 0.90 (varies by text quality)

### Template Selection

```kotlin
// GameScreen.kt
enum class GameScreen(
    val code: Int,
    val templatePath: String,
    val description: String,
    val useLens: Boolean = true  // Choose endpoint
)
```

**When to use `lens`:**
- Small UI elements (buttons, icons)
- Unique visual patterns
- Need precise location

**When to use `match`:**
- Full screen comparisons
- Loading screens
- Background validation

## 📸 Template Creation

### Requirements

✅ **Resolution**: 1280x720 (landscape)  
✅ **Size**: 100-500px wide (medium)  
✅ **Quality**: Include context for uniqueness  
✅ **Format**: PNG (lossless)

### Best Practices

**❌ Bad Template:**
```
[  Green Button  ]
```
- Too generic
- Matches any green element
- No context

**✅ Good Template:**
```
┌───────────────────────────┐
│ [Yellow Text Above]       │
│ [Character Icon] [Button] │
│ [Other UI Elements]       │
└───────────────────────────┘
```
- Includes context
- Unique combination
- Precise boundaries

### Capture Process

```bash
# 1. Screenshot device
adb shell screencap -p > /tmp/screen.png

# 2. Open in Preview
open /tmp/screen.png

# 3. Select region with context
#    - Target element
#    - Surrounding unique elements
#    - 200-500px wide

# 4. Copy (⌘+C), New (⌘+N), Paste (⌘+V)

# 5. Save as template
#    app/src/main/assets/templates/[category]/[name].png

# 6. Verify size
sips -g pixelWidth -g pixelHeight template.png
```

See: [templates/ddt/login/README.md](../app/src/main/assets/templates/ddt/login/README.md)

## 🧪 Testing

### Test API Locally

```bash
# Health check
curl http://localhost:8000/health

# Test lens endpoint (requires base64 images)
curl -X POST http://localhost:8000/lens \
  -H "Content-Type: application/json" \
  -d '{"object_image":"...","screen_image":"...","threshold":0.9}'
```

### Test in Android App

```kotlin
// From Use Case
val result = screenValidator.validateScreen(
    screenshot = screenshot,
    expectedScreen = GameScreen.LOGIN_BUTTON,
    minConfidence = 0.90f
)

if (result.isSuccess) {
    val match = result.getOrNull()
    AutoLogger.i("Found at: (${match?.x}, ${match?.y})")
}
```

### View Debug Image

```bash
# After bot runs
./run/view-debug.sh

# Shows:
# - Green box = Detected region
# - Red circle = Click point
# - Confidence and variance metrics
```

## 🔬 Algorithm Details

### Dual-Method Validation

The Vision API uses **two** OpenCV methods and requires agreement:

```python
methods = {
    'TM_CCOEFF_NORMED': cv2.TM_CCOEFF_NORMED,  # Correlation
    'TM_CCORR_NORMED': cv2.TM_CCORR_NORMED,     # Normalized correlation
}

# Calculate average confidence
avg_confidence = (method1_conf + method2_conf) / 2

# Check location agreement
location_variance = distance_between_detections

# Accept only if BOTH pass:
found = (avg_confidence >= threshold) and (location_variance < 20px)
```

**Why?** Single method can be fooled by generic patterns. Dual validation ensures precision.

### Auto-Rotation

Handles orientation mismatches automatically:

```python
# If dimensions are inverted (e.g., 720x1280 vs 1280x720)
if obj_h == scr_w and obj_w == scr_h:
    object_img = cv2.rotate(object_img, cv2.ROTATE_90_CLOCKWISE)
```

## 🐛 Troubleshooting

### "Vision API connection failed"

**Cause**: Docker container not running

**Solution**:
```bash
# Check status
docker ps | grep vision

# Start if needed
cd automation-vision-ocr
./start-vision-api.sh

# Or restart
cd automation-bot-ddt
./run/restart-vision.sh
```

### Low Confidence / Not Found

**Cause**: Template doesn't match screenshot

**Common Issues:**
1. Template captured in wrong resolution
2. Template too generic (matches multiple things)
3. Template missing context
4. Screen changed (UI update, different state)

**Solution**:
1. Recapture template in 1280x720 landscape
2. Include more context around target element
3. Increase template size to 200-500px
4. Verify screenshot shows expected screen

### False Positives

**Cause**: Generic pattern matching similar elements

**Example**:
- Template: Green button
- Detected: Any green element (logo, background, etc.)

**Solution**:
1. Add surrounding context to template
2. Increase confidence threshold (0.90+)
3. Use more distinctive visual elements
4. Include text/icons that make it unique

### Click Position Incorrect

**Cause**: Template includes padding or wrong bounds

**Solution**:
1. Recapture template tightly around target
2. No extra whitespace
3. Check debug image (`view-debug.sh`)
4. Verify green box aligns with actual element

## 📊 Performance Metrics

| Metric | v2 | v3 | Status |
|--------|----|----|--------|
| Accuracy | 75% | 93%+ | ✅ +18% |
| False Positives | 10% | <1% | ✅ -90% |
| Response Time | 1-2s | <1s | ✅ Fast |
| Variance | ±30px | 0px | ✅ Perfect |

## 🔍 Debug Mode

### Visual Debug Images

Every detection generates a debug image at `/tmp/vision_debug.jpg` in the Docker container.

**Shows:**
- Green rectangle: Detected region
- Red circle: Calculated click center
- Text labels: Confidence, variance, size

**View:**
```bash
./run/view-debug.sh
```

### Verbose Logging

```python
# vision_service.py includes detailed logs:
print(f"[LENS DEBUG] Object: {obj_w}x{obj_h}, Screen: {scr_w}x{scr_h}")
print(f"[LENS DEBUG] Method TM_CCOEFF_NORMED: confidence={conf:.4f}")
print(f"[LENS DEBUG] Average confidence: {avg:.4f}, variance: {var}px")
```

**Check:**
```bash
docker logs ddt-vision-api --tail 50
```

## 🚀 Deployment

### Start Vision API

```bash
cd automation-vision-ocr
./start-vision-api.sh

# Starts Colima (if needed) + builds + runs Docker container
# Accessible at: http://localhost:8000
```

### Stop Vision API

```bash
cd automation-vision-ocr
./stop-vision-api.sh

# Or via run scripts:
cd automation-bot-ddt
./run/restart-vision.sh
```

### Docker Commands

```bash
# Build
docker build -t ddt-vision-api .

# Run
docker run -d --name ddt-vision-api -p 8000:8000 ddt-vision-api

# Logs
docker logs ddt-vision-api -f

# Stop
docker stop ddt-vision-api && docker rm ddt-vision-api
```

## 📚 Related Documentation

- [SCREENSHOT-GUIDE.md](SCREENSHOT-GUIDE.md) - Screenshot capture
- [Template README](../app/src/main/assets/templates/ddt/login/README.md) - Template guide
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Quick commands

## 🎓 Key Learnings

1. **Context is Critical**: Generic templates cause false positives
2. **Dual Validation**: Single method can be fooled, use multiple
3. **Resolution Matters**: Always capture in target resolution (1280x720)
4. **Size Matters**: Too small = duplicates, too large = slow/failures
5. **Debug Visually**: Always check debug images when tuning

## ✅ Current Status

- ✅ Dual-method validation (TM_CCOEFF + TM_CCORR)
- ✅ Location agreement required (<20px variance)
- ✅ Auto-rotation for orientation mismatches
- ✅ Visual debug images with metrics
- ✅ 93%+ accuracy, <1% false positives
- ✅ <1s response time

**Last Updated**: 2026-03-03 (v3)
