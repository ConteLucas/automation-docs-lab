# 📝 Code Standards

## 🌐 Language

**ALL code must be in ENGLISH:**
- ✅ Comments
- ✅ Variable names
- ✅ Function names
- ✅ Class names
- ✅ Log messages
- ✅ UI text (strings.xml)

### ❌ Wrong:
```kotlin
// Abre o jogo
fun abrirJogo() {
    log("Iniciando jogo...")
}
```

### ✅ Correct:
```kotlin
// Opens the game
fun openGame() {
    log("Starting game...")
}
```

---

## 📛 Naming Conventions

### Classes: PascalCase
```kotlin
class AppLauncher
class ScreenCapture
class TemplateManager
```

### Functions: camelCase
```kotlin
fun captureScreen()
fun matchTemplate()
fun isInstalled()
```

### Variables: camelCase
```kotlin
val packageName = "com.game"
val isInstalled = true
var retryCount = 0
```

### Constants: UPPER_SNAKE_CASE
```kotlin
const val DDTANK_PACKAGE = "com.road7.ddtankbr.gp"
const val MAX_RETRIES = 3
const val API_TIMEOUT = 30000
```

---

## 📄 Documentation

### Class Documentation:
```kotlin
/**
 * AppLauncher
 * 
 * WHAT IT DOES:
 * Opens and closes applications on Android.
 * 
 * HOW IT WORKS:
 * Uses PackageManager to get launch intents.
 * 
 * DEPENDENCIES:
 * - Context: Required for PackageManager access
 * - Timber: Logging framework
 */
class AppLauncher(private val context: Context) {
```

### Function Documentation:
```kotlin
/**
 * Opens an application by package name
 * 
 * @param packageName App package (e.g., "com.whatsapp")
 * @return true if successfully opened, false otherwise
 * 
 * USAGE EXAMPLE:
 * val opened = launcher.launch("com.whatsapp")
 * if (opened) println("Success!")
 */
fun launch(packageName: String): Boolean {
```

---

## 🎯 Code Structure

### Single Responsibility:
```kotlin
// ❌ Wrong - MainActivity doing everything
class MainActivity {
    fun captureScreen() { /* logic */ }
    fun matchTemplate() { /* logic */ }
    fun executeAction() { /* logic */ }
}

// ✅ Correct - Each class has one responsibility
class ScreenCapture { fun capture() { } }
class TemplateManager { fun match() { } }
class ActionExecutor { fun execute() { } }
```

---

## 🪵 Logging

### Use Timber:
```kotlin
// Info
Timber.i("App launched successfully")

// Debug
Timber.d("Found ${apps.size} apps")

// Warning
Timber.w("Force stop failed")

// Error
Timber.e(exception, "Failed to launch app")
```

### Log Messages:
```kotlin
✅ "Starting DDTank BR..."
✅ "App launched successfully"
✅ "Template not found"

❌ "iniciando jogo"
❌ "app aberto"
```

---

## 🔤 String Resources

### strings.xml (English):
```xml
<string name="app_name">Bot DDT</string>
<string name="game_not_installed">Game not installed</string>
<string name="starting_game">Starting game...</string>
```

---

## 🎨 Code Formatting

### Indentation: 4 spaces
```kotlin
class Example {
    fun method() {
        if (condition) {
            doSomething()
        }
    }
}
```

### Line Length: Max 120 characters
```kotlin
// ✅ Good
val result = templateManager.loadTemplateAsBytes("ddtank/login/btn.png")

// ❌ Too long
val result = templateManager.loadTemplateAsBytesFromTheSpecificLocationInTheAssetsDirectory("ddtank/login/button_enter_game_main_screen.png")
```

---

## 🏗️ Architecture

### Layer Responsibilities:

**ui/** - User Interface
```kotlin
// ✅ What MainActivity SHOULD do:
- Initialize components
- Orchestrate flow
- Display logs
- Handle lifecycle

// ❌ What MainActivity should NOT do:
- HTTP calls
- File manipulation
- Complex logic
- Direct automation
```

**automation/** - Automation Logic
```kotlin
// ✅ AppLauncher, ScreenCapture, ActionExecutor
// Pure automation logic, no UI
```

**api/** - External Communication
```kotlin
// ✅ VisionApiService, CoreApiService
// Only API calls and models
```

**data/** - Data Management
```kotlin
// ✅ ConfigRepository
// SharedPreferences, database access
```

---

## ✅ Good Practices

### Null Safety:
```kotlin
// Use safe calls
val name = appLauncher.getAppName(package)?.uppercase()

// Use elvis operator
val url = config.getVisionApiUrl() ?: "http://default.com"
```

### Error Handling:
```kotlin
try {
    context.startActivity(intent)
    return true
} catch (e: Exception) {
    Timber.e(e, "Failed to launch app")
    return false
}
```

### Coroutines:
```kotlin
// Use lifecycleScope in Activities
lifecycleScope.launch {
    val screenshot = screenCapture.captureScreen()
    log("Captured: ${screenshot?.size} bytes")
}

// Use withContext for IO operations
suspend fun loadTemplate() = withContext(Dispatchers.IO) {
    // File operation
}
```

---

## 🚫 Avoid

- ❌ Portuguese comments or names
- ❌ God classes (classes that do everything)
- ❌ Magic numbers (use constants)
- ❌ Hardcoded strings (use constants/resources)
- ❌ Swallowing exceptions silently
- ❌ Long functions (> 50 lines)

---

## ✅ Always

- ✅ Write in English
- ✅ Document complex logic
- ✅ Use meaningful names
- ✅ Keep functions small
- ✅ Follow Single Responsibility
- ✅ Log important actions
- ✅ Handle errors properly
