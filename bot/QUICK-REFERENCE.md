# Quick Reference - Screen Validation

## 📁 File Structure

```
automation-bot-ddt/
├── app/src/main/
│   ├── java/com/automation/bot/
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── GameScreen.kt          ← Enum with screen codes
│   │   │   │   └── ScreenMatch.kt         ← Result model
│   │   │   └── usecases/
│   │   │       ├── ScreenValidator.kt     ← Generic validator (with retry)
│   │   │       └── FlowLoginUseCase.kt    ← Login-specific logic
│   │   ├── automation/
│   │   │   ├── AppLauncher.kt             ← Opens apps
│   │   │   └── ScreenCapture.kt           ← Takes screenshots (TODO)
│   │   ├── templates/
│   │   │   └── TemplateManager.kt         ← Loads images from assets
│   │   ├── api/
│   │   │   └── VisionApiService.kt        ← Mock (always true)
│   │   └── ui/
│   │       ├── MainActivity.kt            ← Orchestrator
│   │       └── FloatingLogWindow.kt       ← Floating UI
│   └── assets/templates/
│       └── ddt/
│           ├── login/
│           │   ├── screen_login.png       ← PUT YOUR SCREENSHOT HERE
│           │   └── README.md
│           ├── menu/
│           └── battle/
```

## 🔄 Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. USER OPENS APP                                            │
└──────────────┬──────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. MainActivity.onCreate()                                   │
│    - Initializes components                                  │
│    - Requests overlay permission                             │
│    - Starts automation                                       │
└──────────────┬──────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. openDDTank()                                              │
│    - Shows floating log window                               │
│    - Launches DDT game                                       │
│    - Waits 3 seconds                                         │
└──────────────┬──────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. checkLoginScreen()                                        │
│    - Calls FlowLoginUseCase.execute()                        │
└──────────────┬──────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. FlowLoginUseCase.execute()                                │
│    - Calls ScreenValidator.validateScreenWithRetry()         │
└──────────────┬──────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. ScreenValidator (MAX 5 ATTEMPTS)                          │
│                                                               │
│    Attempt 1:                                                │
│    ├─→ ScreenCapture.takeScreenshot()                        │
│    ├─→ TemplateManager.loadTemplateAsBytes()                 │
│    └─→ VisionApiService.matchTemplate()                      │
│         └─→ MOCK returns: { match: true, confidence: 95% }   │
│                                                               │
│    ✓ Match found! Return success                             │
│                                                               │
│    (If no match, wait 2s and try again)                      │
└──────────────┬──────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. Result back to MainActivity                               │
│    - Log: "Login screen detected!"                           │
│    - Log: "Confidence: 95.0%"                                │
│    - Log: "Ready to proceed!"                                │
└─────────────────────────────────────────────────────────────┘
```

## 📝 What Each Component Does

| Component | What It Does | Status |
|-----------|--------------|--------|
| **GameScreen** | Enum with screen codes (101, 102, ...) | ✅ Ready |
| **ScreenCapture** | Takes screenshot of current screen | ⏳ Placeholder (returns null) |
| **TemplateManager** | Loads images from `assets/templates/` | ✅ Ready |
| **VisionApiService** | Compares screenshot vs template | ✅ Mock (always true) |
| **ScreenValidator** | Validates screen with retry logic | ✅ Ready |
| **FlowLoginUseCase** | Login screen specific logic | ✅ Ready |
| **MainActivity** | Orchestrates everything | ✅ Ready |

## 🎯 Current Behavior (Mock Mode)

Since `VisionApiService` is mocked:

1. ScreenCapture returns `null` → Validator uses mock
2. Template not found → Validator uses mock
3. Vision API called → Always returns `true` with 95% confidence
4. **Result:** Login screen is "always detected" successfully

## 🔧 Next Steps

### Immediate (Testing)
1. Run `./run.sh` to install app
2. Open app on emulator
3. Grant overlay permission
4. Watch floating log window
5. See: "Login screen detected! Confidence: 95.0%"

### Short-term (Real Implementation)
1. **Add real screenshot:**
   - Capture DDT login screen
   - Save as `app/src/main/assets/templates/ddt/login/screen_login.png`
   
2. **Implement ScreenCapture:**
   - Use MediaProjection API
   - Return real Bitmap instead of null

3. **Keep mock Vision API:**
   - Still returns true for testing
   - But now uses real images

### Long-term (Production)
1. **Develop Vision Service:**
   - Python FastAPI
   - OpenCV for template matching
   - Returns real match results

2. **Replace mock:**
   - Use Retrofit
   - Call real Vision API

3. **Database migration:**
   - Store templates in DB
   - Send only code instead of image

## 🐛 Resilience

### Retry Logic
```kotlin
validateScreenWithRetry(
    expectedScreen = GameScreen.LOGIN_SCREEN,
    maxAttempts = 5,     // Try 5 times
    delayMs = 2000       // Wait 2 seconds between attempts
)
```

### What Happens After 5 Failures?
```kotlin
Result.failure(Exception("Login screen not detected"))
```

**Future improvements:**
- Send error log via email
- Take diagnostic screenshot
- Restart game
- Try alternative account
- Notify monitoring system

## 💡 Key Advantages

1. **Clean Architecture**
   - MainActivity has NO complex logic
   - Everything is delegated to UseCases
   - Easy to test each component

2. **Reusable**
   - `ScreenValidator` works for ANY screen
   - Just add new enum entry + UseCase

3. **Future-proof**
   - Ready for DB migration
   - Ready for real Vision Service
   - Ready for real screenshots

4. **Testable**
   - Mock allows testing without Vision Service
   - Each component can be tested independently

## ❓ FAQ

**Q: Where do I put screenshots?**
A: `app/src/main/assets/templates/ddt/login/screen_login.png`

**Q: How do I add a new screen?**
A: 3 steps:
1. Add to `GameScreen` enum
2. Put image in `assets/templates/`
3. Create UseCase (copy `FlowLoginUseCase` as template)

**Q: Why is it always detecting?**
A: VisionApiService is mocked (always returns true)

**Q: How to test with real images?**
A: Implement `ScreenCapture.takeScreenshot()` first

**Q: Where is the click functionality?**
A: TODO in `FlowLoginUseCase.clickAt()` - will use UIAutomator

**Q: Why codes (101, 102, ...)?**
A: Prepares for DB migration. Vision Service will fetch templates by code.

---

📚 **See also:** `SCREEN-VALIDATION.md` for detailed architecture
