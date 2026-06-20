# 🎨 UI Guide

Complete guide for the user interface components of the automation bot.

## 🎯 Overview

The bot has a minimal UI focused on **non-intrusive automation**:
- Floating log window (main interface)
- Visual click effects
- Permission screens (MainActivity)

## 🏗️ Architecture

```
MainActivity (Setup)
    ↓
FloatingLogWindow (Runtime UI)
    ↓
ClickEffectOverlay (Visual Feedback)
```

### Components

1. **MainActivity** - Initial setup and permissions
2. **FloatingLogWindow** - Main runtime interface
3. **ClickEffectOverlay** - Visual click feedback

## 📱 MainActivity

### Purpose

- Request MediaProjection permission
- Request Accessibility Service permission
- Start/stop automation
- Launch floating window

### Layout

```
┌──────────────────────────────────┐
│  Automation Bot                  │
│                                  │
│  [START]  [STOP]                │
│                                  │
│  Status: Ready                   │
│                                  │
│  Permissions:                    │
│  ✓ MediaProjection              │
│  ✓ Accessibility                │
│  ✓ System Alert Window          │
└──────────────────────────────────┘
```

### Key Features

**START Button:**
- Requests permissions if needed
- Starts MediaProjectionService
- Initializes FloatingLogWindow
- Begins automation

**STOP Button:**
- Stops automation
- Keeps floating window (for logs)
- Releases resources

### Permissions

```kotlin
// Modern API for MediaProjection
private val mediaProjectionLauncher = registerForActivityResult(
    ActivityResultContracts.StartActivityForResult()
) { result ->
    if (result.resultCode == Activity.RESULT_OK) {
        startMediaProjectionService(result.resultCode, result.data)
    }
}

// Accessibility Service
private fun requestAccessibilityPermission() {
    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
    startActivity(intent)
}
```

## 🪟 FloatingLogWindow

### Purpose

The **main runtime interface** - shows logs and status over any app.

### Features

- ✅ **Overlay**: Displays over game and all apps
- ✅ **Real-time logs**: Updates as events happen
- ✅ **Collapsible**: Minimize to small icon
- ✅ **Draggable**: Move anywhere on screen
- ✅ **Scrollable**: View log history
- ✅ **Auto-scroll**: Latest logs always visible

### States

**Collapsed (Icon):**
```
┌────┐
│ 🤖 │  BOT
└────┘
```
- Minimal footprint
- Tap to expand
- Drag to reposition

**Expanded (Full):**
```
┌────────────────────────────────┐
│ 🤖 Bot Logs            [−]     │
├────────────────────────────────┤
│ 12:00:00 [INFO] Bot started    │
│ 12:00:05 [INFO] Detecting...   │
│ 12:00:10 [INFO] ✓ Found!       │
│ 12:00:15 [INFO] Clicking...    │
│ ...                            │
└────────────────────────────────┘
```
- Shows log history
- Tap [−] to collapse
- Drag header to move
- Scroll to see older logs

### Implementation

```kotlin
// FloatingLogWindow.kt
class FloatingLogWindow(private val context: Context) {
    
    // Window parameters
    private val params = WindowManager.LayoutParams(
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
        PixelFormat.TRANSLUCENT
    )
    
    // Add log entry
    fun addLog(level: String, message: String) {
        val formattedLog = formatLog(level, message)
        logs.add(formattedLog)
        
        // Keep only last 100 lines
        if (logs.size > MAX_LOG_LINES) {
            logs.removeAt(0)
        }
        
        updateUI()
    }
}
```

### Customization

```kotlin
// Max lines to keep
private val MAX_LOG_LINES = 100

// Colors
private val COLOR_DEBUG = Color.GRAY
private val COLOR_INFO = Color.BLUE
private val COLOR_WARN = Color.YELLOW
private val COLOR_ERROR = Color.RED

// Size (collapsed)
private val COLLAPSED_WIDTH = 200  // dp
private val COLLAPSED_HEIGHT = 80  // dp

// Size (expanded)
private val EXPANDED_WIDTH = 350  // dp
private val EXPANDED_HEIGHT = 500 // dp
```

### Usage

```kotlin
// In MainActivity or BotViewModel
val floatingWindow = FloatingLogWindow(context)

// Show window
floatingWindow.show()

// Add logs
floatingWindow.addLog("INFO", "Bot started")
floatingWindow.addLog("ERROR", "Connection failed")

// Hide window
floatingWindow.hide()
```

## ✨ ClickEffectOverlay

### Purpose

Show **visual feedback** when clicks are executed.

### Appearance

```
     ⬤ ← Ripple effect
   ⬤ ⬤    at click point
     ⬤
```

### Features

- ✅ **Instant feedback**: Shows exactly where clicked
- ✅ **Non-intrusive**: Fades quickly (300ms)
- ✅ **Works anywhere**: Overlays all apps
- ✅ **No touch blocking**: Click passes through

### Implementation

```kotlin
// ClickEffectOverlay.kt
class ClickEffectOverlay(private val context: Context) {
    
    fun show(x: Int, y: Int) {
        // Create circular view
        val effectView = createCircleView()
        
        // Position at click point
        params.x = x - (circleSize / 2)
        params.y = y - (circleSize / 2)
        
        // Add to window
        windowManager.addView(effectView, params)
        
        // Fade out animation
        effectView.animate()
            .alpha(0f)
            .setDuration(300)
            .withEndAction {
                windowManager.removeView(effectView)
            }
    }
}
```

### Customization

```kotlin
// Circle size
private val CIRCLE_SIZE = 100  // dp

// Duration
private val FADE_DURATION = 300L  // ms

// Color
private val CIRCLE_COLOR = Color.RED
private val CIRCLE_ALPHA = 0.5f  // 50% transparent
```

### Usage

```kotlin
// In ScreenClicker
class ScreenClicker {
    private val clickEffect = ClickEffectOverlay(context)
    
    fun clickAt(x: Int, y: Int) {
        // Show effect
        clickEffect.show(x, y)
        
        // Execute click
        accessibilityService.click(x, y)
    }
}
```

## 🎨 Color Scheme

### Log Levels

| Level | Color | Hex |
|-------|-------|-----|
| DEBUG | Gray | `#808080` |
| INFO | Blue | `#2196F3` |
| WARN | Yellow | `#FFC107` |
| ERROR | Red | `#F44336` |

### UI Elements

| Element | Color | Hex |
|---------|-------|-----|
| Background | Dark Gray | `#212121` |
| Text | White | `#FFFFFF` |
| Border | Light Gray | `#BDBDBD` |
| Accent | Green | `#4CAF50` |

## 📐 Layout Guidelines

### Floating Window

**Collapsed:**
- Width: 200dp (fits icon + text)
- Height: 80dp (2 lines)
- Position: Top-right by default

**Expanded:**
- Width: 350dp (readable logs)
- Height: 500dp (enough history)
- Max lines: 100 (prevent memory issues)

### Click Effect

- Size: 100dp (visible but not intrusive)
- Duration: 300ms (quick feedback)
- Alpha: 50% (see through to content)

## 🔧 Permissions

### SYSTEM_ALERT_WINDOW

Required for floating window and click effects.

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
```

**Request:**
```kotlin
if (!Settings.canDrawOverlays(context)) {
    val intent = Intent(
        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
        Uri.parse("package:${context.packageName}")
    )
    startActivity(intent)
}
```

## 🐛 Troubleshooting

### Floating Window Not Showing

**Cause**: Permission not granted

**Solution**:
```kotlin
// Check permission
if (!Settings.canDrawOverlays(context)) {
    // Request in MainActivity
    requestOverlayPermission()
}
```

### Window Not Draggable

**Cause**: Touch events not handled

**Solution**:
```kotlin
// Ensure onTouchListener is set
headerView.setOnTouchListener { view, event ->
    when (event.action) {
        MotionEvent.ACTION_DOWN -> // Handle down
        MotionEvent.ACTION_MOVE -> // Handle drag
        MotionEvent.ACTION_UP -> // Handle up
    }
    true
}
```

### Click Effect Not Visible

**Cause**: Overlay permission or z-order issue

**Solution**:
```kotlin
// Verify TYPE_APPLICATION_OVERLAY is used
val params = WindowManager.LayoutParams(
    ...,
    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,  // Correct type
    ...
)
```

### Logs Not Updating

**Cause**: UI thread not used for updates

**Solution**:
```kotlin
// Always update UI on main thread
fun addLog(message: String) {
    runOnUiThread {
        // Update views here
    }
}
```

## 📊 Performance

| Component | Memory | CPU | Notes |
|-----------|--------|-----|-------|
| FloatingLogWindow | ~1MB | Minimal | Circular buffer |
| ClickEffectOverlay | <100KB | Minimal | Temporary views |
| MainActivity | ~2MB | Low | Only during setup |

## 🎯 Best Practices

### DO ✅

- Keep floating window collapsible
- Use consistent colors for log levels
- Show visual feedback for clicks
- Allow window repositioning
- Auto-scroll to latest logs
- Limit log history (100 lines max)

### DON'T ❌

- Block touch events unnecessarily
- Keep too many log lines (memory)
- Use bright/distracting colors
- Make window too large
- Update UI from background threads
- Show sensitive information in logs

## 📚 Related Documentation

- [LOGGING-GUIDE.md](LOGGING-GUIDE.md) - Logging system
- [ACCESSIBILITY-GUIDE.md](ACCESSIBILITY-GUIDE.md) - Click system
- [ANDROID-PERMISSIONS-EXPLAINED.md](ANDROID-PERMISSIONS-EXPLAINED.md) - Permissions

## 🎓 Key Learnings

1. **Floating Window Essential**: Best way to show status during automation
2. **Collapsible is Key**: Minimize when not needed
3. **Visual Feedback Matters**: Click effects help debugging
4. **Overlay Permission Tricky**: Users often deny it initially
5. **UI Thread Always**: All view updates must be on main thread

## ✅ Current Status

- ✅ Floating log window (collapsible, draggable)
- ✅ Visual click effects
- ✅ Real-time log updates
- ✅ Auto-scroll to latest
- ✅ Minimal and non-intrusive
- ✅ All permissions handled gracefully

**Last Updated**: 2026-03-03 (v3)
