# Screen Validation Architecture

## Overview

This document explains how the Bot validates game screens using template matching.

## Flow Diagram

```
MainActivity
    ↓
    launches DDT
    ↓
MenuLoginUseCase.execute()
    ↓
ScreenValidator.validateScreenWithRetry()
    ↓
    ├─→ ScreenCapture.takeScreenshot()      (captures current screen)
    ├─→ TemplateManager.loadTemplateAsBytes() (loads expected image)
    └─→ VisionApiService.matchTemplate()    (compares both)
         ↓
         returns ScreenMatch { isMatch, confidence }
```

## Components

### 1. GameScreen (Enum)

**Location:** `domain/models/GameScreen.kt`

**Purpose:** Defines all game screens with unique codes and template paths.

**Example:**
```kotlin
enum class GameScreen(val code: Int, val templatePath: String) {
    LOGIN_SCREEN(101, "ddt/login/screen_login.png"),
    MAIN_MENU(201, "ddt/menu/screen_main.png")
}
```

**Why codes?**
- Future migration to database will be easier
- Each screen has a unique identifier
- Easy to log and track

### 2. ScreenCapture

**Location:** `automation/ScreenCapture.kt`

**Purpose:** Captures the current screen as a Bitmap.

**Status:** Placeholder (returns null for now)

**TODO:** Implement using MediaProjection API

**Methods:**
- `takeScreenshot()` - Captures screen
- `saveBitmap()` - Saves to file
- `bitmapToByteArray()` - Converts for API

### 3. TemplateManager

**Location:** `templates/TemplateManager.kt`

**Purpose:** Loads template images from `assets/templates/`.

**Status:** ✅ Already implemented

**Methods:**
- `loadTemplate()` - Returns InputStream
- `loadTemplateAsBytes()` - Returns ByteArray
- `templateExists()` - Checks if file exists

### 4. VisionApiService

**Location:** `api/VisionApiService.kt`

**Purpose:** Compares screenshot with template.

**Status:** ✅ Mock (always returns true)

**Methods:**
- `matchTemplate(screenshot, templateName, threshold)` → MatchResult

**Mock behavior:**
```kotlin
suspend fun matchTemplate(...): MatchResult {
    delay(200)  // Simulates network
    return MatchResult(
        match = true,
        confidence = 0.95f,
        coordinates = Coordinates(500, 300, 200, 80)
    )
}
```

### 5. ScreenValidator

**Location:** `domain/usecases/ScreenValidator.kt`

**Purpose:** Orchestrates the validation flow.

**Methods:**

#### `validateScreen(expectedScreen)`
Single validation attempt.

#### `validateScreenWithRetry(expectedScreen, maxAttempts, delayMs)`
Validates with retry logic:
- Tries up to `maxAttempts` times (default: 5)
- Waits `delayMs` between attempts (default: 2000ms)
- Returns as soon as match is found
- Returns failure if all attempts fail

**Example:**
```kotlin
val result = screenValidator.validateScreenWithRetry(
    expectedScreen = GameScreen.LOGIN_SCREEN,
    maxAttempts = 5,
    delayMs = 2000
)

if (result.isMatch) {
    // Found!
}
```

### 6. MenuLoginUseCase

**Location:** `domain/usecases/MenuLoginUseCase.kt`

**Purpose:** Specific use case for login screen interaction.

**What it does:**
1. Validates login screen (with retry)
2. Returns success/failure

**Future:** Will also click on login button.

**Example:**
```kotlin
val loginUseCase = MenuLoginUseCase(context, visionApi)
val result = loginUseCase.execute()

if (result.isSuccess) {
    val match = result.getOrNull()
    println("Login screen found! Confidence: ${match.confidence}")
}
```

## Data Models

### ScreenMatch
```kotlin
data class ScreenMatch(
    val isMatch: Boolean,
    val confidence: Float,          // 0.0 to 1.0
    val expectedScreen: GameScreen,
    val coordinates: ScreenCoordinates?
)
```

### ScreenCoordinates
```kotlin
data class ScreenCoordinates(
    val x: Int,
    val y: Int,
    val width: Int,
    val height: Int
)
```

## How MainActivity Uses It

```kotlin
class MainActivity : AppCompatActivity() {
    
    private lateinit var visionApi: VisionApiService
    private lateinit var menuLoginUseCase: MenuLoginUseCase
    
    override fun onCreate(...) {
        visionApi = VisionApiService()
        menuLoginUseCase = MenuLoginUseCase(this, visionApi)
        
        // ... launch game ...
    }
    
    private fun checkLoginScreen() {
        lifecycleScope.launch {
            val result = menuLoginUseCase.execute()
            
            if (result.isSuccess) {
                // Login screen found!
            }
        }
    }
}
```

## Retry Logic Flow

```
Attempt 1: Take screenshot → Compare → No match → Wait 2s
Attempt 2: Take screenshot → Compare → No match → Wait 2s
Attempt 3: Take screenshot → Compare → MATCH! → Return success
```

If all 5 attempts fail:
```
Attempt 5: Take screenshot → Compare → No match → Return failure
```

## Template Storage

```
app/src/main/assets/templates/
└── ddt/
    ├── login/
    │   ├── screen_login.png      ← Full login screen
    │   └── btn_enter.png         ← Enter button
    ├── menu/
    │   └── screen_main.png
    └── battle/
        └── screen_lobby.png
```

## Future Enhancements

### 1. Database Migration
Instead of:
```kotlin
// Bot sends both screenshot + template
visionApi.matchTemplate(screenshot, templateBytes)
```

We'll send:
```kotlin
// Bot sends only screenshot + code
visionApi.matchTemplate(screenshot, code: 101)
// Vision Service fetches template from DB using code
```

### 2. Real Screenshot
Implement `ScreenCapture` using MediaProjection API:
```kotlin
class ScreenCapture(context: Context) {
    fun takeScreenshot(): Bitmap {
        // Use MediaProjection to capture screen
    }
}
```

### 3. Real Vision Service
Replace mock with Retrofit:
```kotlin
interface VisionApi {
    @POST("/api/match")
    suspend fun matchTemplate(
        @Body request: MatchRequest
    ): MatchResult
}
```

### 4. Click Functionality
Add UIAutomator to click on coordinates:
```kotlin
fun clickAt(x: Int, y: Int) {
    val device = UiDevice.getInstance(instrumentation)
    device.click(x, y)
}
```

## Testing Without Vision Service

Since VisionApiService is mocked:
1. It always returns `match = true`
2. You can test the entire flow
3. No need to have Vision Service running
4. No need to have real screenshots

## Adding New Screens

1. Add to `GameScreen` enum:
```kotlin
enum class GameScreen(...) {
    NEW_SCREEN(401, "ddt/new/screen.png", "Description")
}
```

2. Create template folder:
```bash
mkdir -p app/src/main/assets/templates/ddt/new/
```

3. Add screenshot:
```
app/src/main/assets/templates/ddt/new/screen.png
```

4. Create UseCase:
```kotlin
class NewScreenUseCase(context: Context, visionApi: VisionApiService) {
    private val screenValidator = ScreenValidator(context, visionApi)
    
    suspend fun execute(): Result<ScreenMatch> {
        val result = screenValidator.validateScreenWithRetry(
            expectedScreen = GameScreen.NEW_SCREEN
        )
        return if (result.isMatch) {
            Result.success(result)
        } else {
            Result.failure(Exception("Screen not found"))
        }
    }
}
```

5. Use in MainActivity:
```kotlin
private fun checkNewScreen() {
    lifecycleScope.launch {
        val result = newScreenUseCase.execute()
        // Handle result
    }
}
```

## Questions?

This architecture keeps:
- ✅ MainActivity clean (no complex logic)
- ✅ UseCases reusable and testable
- ✅ Easy to add new screens
- ✅ Ready for future DB migration
- ✅ Works without Vision Service (mocked)
