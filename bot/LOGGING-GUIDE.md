# 📝 Logging Guide

Complete guide for the unified logging system in the automation bot.

## 🎯 Overview

The bot uses a **centralized logging system** (`AutoLogger`) that outputs to multiple destinations simultaneously.

### Log Destinations

1. **Logcat** - Android system logs (adb logcat)
2. **FloatingLogWindow** - Visual overlay on device
3. **Log Files** - Persistent files on device storage

All three stay synchronized in real-time.

## 🏗️ Architecture

```
Code Call
    ↓
AutoLogger.i("Message")
    ↓
┌─────────┬──────────────┬────────────┐
│         │              │            │
Logcat    Floating       Log File
(adb)     Window         (/sdcard/...)
          (UI Overlay)
```

### Components

1. **AutoLogger** (`utils/AutoLogger.kt`)
   - Main logging interface
   - Centralized point for all logs
   - Formats messages consistently

2. **FloatingLogWindow** (`ui/FloatingLogWindow.kt`)
   - Visual log display over other apps
   - Real-time updates
   - Scrollable, collapsible

3. **LogFileManager** (`utils/LogFileManager.kt`)
   - Saves logs to files
   - Auto-cleanup (keeps last 3)
   - Session timestamps

4. **LogcatMonitor** (`utils/LogcatMonitor.kt`)
   - Monitors external app logs (DDT game)
   - Re-routes to AutoLogger
   - Background coroutine

## 🚀 Usage

### Basic Logging

```kotlin
// Info
AutoLogger.i("Bot started successfully")

// Debug
AutoLogger.d("Screenshot size: 1280x720")

// Warning
AutoLogger.w("Retry attempt 3/10")

// Error
AutoLogger.e("Failed to connect to Vision API")
```

### With Context

```kotlin
// Use Case logging
class FlowLoginUseCase {
    suspend fun execute() {
        AutoLogger.i("Starting login screen validation...")
        
        val result = screenValidator.validate()
        if (result.isSuccess) {
            AutoLogger.i("✓ Login screen detected")
        } else {
            AutoLogger.e("✗ Login screen not found")
        }
    }
}
```

### From Callbacks

```kotlin
// Passing log callback to components
screenClicker.click(coordinate) { message ->
    AutoLogger.i(message)  // Re-route callback to centralized logger
}
```

## 📊 Log Levels

| Level | Method | When to Use | Color (Logcat) |
|-------|--------|-------------|----------------|
| DEBUG | `AutoLogger.d()` | Development details, metrics | Gray |
| INFO | `AutoLogger.i()` | Normal operation, milestones | Blue |
| WARN | `AutoLogger.w()` | Recoverable issues, retries | Yellow |
| ERROR | `AutoLogger.e()` | Failures, exceptions | Red |

### Level Guidelines

**DEBUG:**
```kotlin
AutoLogger.d("Screen metrics: 1280x720 @ 320dpi")
AutoLogger.d("Attempt 1/10 for screen (101)")
```

**INFO:**
```kotlin
AutoLogger.i("Bot started successfully")
AutoLogger.i("Login screen detected! Confidence: 94.09%")
AutoLogger.i("✓ Click completed successfully")
```

**WARN:**
```kotlin
AutoLogger.w("Screenshot timeout, retrying...")
AutoLogger.w("Low confidence: 75% < 90%")
```

**ERROR:**
```kotlin
AutoLogger.e("Failed to validate screen")
AutoLogger.e("Vision API connection failed")
AutoLogger.e("MediaProjection not initialized")
```

## 🎨 Log Format

### Standard Format

```
YYYY-MM-DD HH:MM:SS - [LEVEL] - message
```

### Examples

```
2026-03-03 12:00:00 - [INFO] - Bot started successfully
2026-03-03 12:00:05 - [DEBUG] - Screenshot captured in 508ms: 1280x720
2026-03-03 12:00:10 - [INFO] - ✓ Login screen detected! Confidence: 94.09%
2026-03-03 12:00:15 - [ERROR] - Failed to connect to Vision API
```

### Unicode Symbols

Use symbols for visual clarity:

```kotlin
// Success
AutoLogger.i("✓ Click completed successfully")
AutoLogger.i("✅ All systems operational")

// Failure
AutoLogger.e("✗ Login screen not found")
AutoLogger.e("❌ Vision API offline")

// Info
AutoLogger.i("📱 Device: emulator-5554")
AutoLogger.i("🔍 Searching for element...")
AutoLogger.i("📊 Confidence: 93.12%")
```

## 📱 Floating Log Window

### Features

- **Real-time updates**: Shows logs as they happen
- **Collapsible**: Minimize to small icon
- **Draggable**: Move anywhere on screen
- **Scrollable**: View history
- **Auto-scroll**: Latest logs always visible

### Controls

- **Tap icon**: Expand/collapse
- **Drag icon**: Reposition window
- **Scroll**: View log history

### Customization

```kotlin
// FloatingLogWindow.kt
private val MAX_LOG_LINES = 100  // Keep last 100 lines
private val AUTO_SCROLL_DELAY = 100L  // ms
```

## 📁 Log Files

### Location

```
/sdcard/Download/automation-bot-ddt/logs/
```

### File Format

```
bot_log_YYYY-MM-DD_HH-mm-ss.txt
```

### Example

```
bot_log_2026-03-03_12-00-00.txt
```

### Content

```
═══════════════════════════════════════════════════════
Bot Session Started: 2026-03-03 12:00:00
═══════════════════════════════════════════════════════

2026-03-03 12:00:01 - [INFO] - MediaProjection initialized
2026-03-03 12:00:05 - [INFO] - DDT game launched
2026-03-03 12:00:10 - [INFO] - Login screen detected
...

═══════════════════════════════════════════════════════
Bot Session Ended: 2026-03-03 12:15:30
Duration: 15m 30s
═══════════════════════════════════════════════════════
```

### Auto-Cleanup

**Automatic (by app):**
- Keeps last 3 log files
- Runs on every bot start
- Deletes oldest first

**Manual:**
```bash
# Keep only latest
./run/clean-logs.sh

# Delete all
./run/clean-all-logs.sh
```

## 🔍 Viewing Logs

### Method 1: Floating Window (Recommended)

- Real-time on device
- No computer needed
- Visual and convenient

### Method 2: Script (Development)

```bash
# Best formatting
./run/watch-formatted.sh emulator-5554

# Shows:
# - Timestamp aligned
# - Level colored
# - Only bot logs (filters noise)
```

### Method 3: Direct ADB

```bash
# Raw logcat
adb logcat | grep AutoLogger

# Filter by level
adb logcat | grep -E "(ERROR|INFO)"
```

### Method 4: Log Files

```bash
# List files
adb shell "ls -lh /sdcard/Download/automation-bot-ddt/logs/"

# View latest
adb shell "cat /sdcard/Download/automation-bot-ddt/logs/bot_log_*.txt | tail -50"

# Pull to computer
adb pull /sdcard/Download/automation-bot-ddt/logs/bot_log_2026-03-03_12-00-00.txt
```

## 🐛 Troubleshooting

### Logs Not Showing in Floating Window

**Cause**: UI thread issue or window not initialized

**Solution**:
1. Check window is expanded (tap icon)
2. Verify SYSTEM_ALERT_WINDOW permission granted
3. Check logs for: "LogcatMonitor error: Only the original thread..."
   - This error is harmless (caught internally)

### Log Files Not Created

**Cause**: Storage permission or directory creation failed

**Solution**:
1. Grant storage permissions
2. Check `/sdcard/Download/` is writable
3. See logs for: "Failed to create log file"

### Too Many Log Files

**Solution**:
```bash
# Manual cleanup
./run/clean-logs.sh

# Or clean all
./run/clean-all-logs.sh
```

### Logs Filling Up Storage

**Auto-cleanup keeps only last 3 files**

If still an issue:
1. Reduce `MAX_LOG_LINES` in FloatingLogWindow
2. Run cleanup scripts more frequently
3. Check for very long-running sessions

## 🎯 Best Practices

### DO ✅

```kotlin
// Be descriptive
AutoLogger.i("Login screen detected! Confidence: 94.09%")

// Include context
AutoLogger.d("Screenshot captured in 508ms: 1280x720")

// Use symbols for clarity
AutoLogger.i("✓ Click completed successfully")

// Log important milestones
AutoLogger.i("Bot started successfully")
AutoLogger.i("Automation completed")
```

### DON'T ❌

```kotlin
// Too vague
AutoLogger.i("Done")

// Too much detail in production
AutoLogger.d("pixel[0][0] = 255, pixel[0][1] = 128...")

// Redundant logs in tight loops
for (i in 0..1000) {
    AutoLogger.d("Processing $i")  // Too much!
}

// Sensitive data
AutoLogger.i("Password: 12345")  // Never!
```

### When to Log

✅ **Log these:**
- Bot lifecycle (start, stop, pause)
- Major state changes (screen detected, clicked)
- Errors and exceptions
- Important metrics (confidence, timing)
- User actions (button pressed)

❌ **Don't log these:**
- Every line of code execution
- Loop iterations
- Variable assignments
- Internal calculations

## 📊 Performance

| Aspect | Impact | Notes |
|--------|--------|-------|
| Memory | Low (~1MB) | Circular buffer, auto-cleanup |
| CPU | Minimal | Async operations |
| Storage | ~100KB/session | Auto-cleaned |
| Network | None | Local only |

## 📚 Related Documentation

- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Quick commands
- [DEVELOPMENT.md](DEVELOPMENT.md) - Development guide
- [utils/scripts/bot/](../../utils/scripts/bot/) - Script documentation

## 🎓 Key Learnings

1. **Centralized is Better**: One logger for all outputs
2. **Visual Helps**: Floating window is invaluable for debugging
3. **Auto-Cleanup Essential**: Log files can accumulate quickly
4. **Symbols Aid Readability**: ✓ ✗ ⚠️ make logs scannable
5. **Async Logging**: Never block main thread for logging

## ✅ Current Status

- ✅ Unified logging across all components
- ✅ Three outputs: Logcat, FloatingWindow, Files
- ✅ Auto-cleanup (keeps last 3 files)
- ✅ Real-time floating window display
- ✅ Manual cleanup scripts
- ✅ Consistent formatting

**Last Updated**: 2026-03-03 (v3)
