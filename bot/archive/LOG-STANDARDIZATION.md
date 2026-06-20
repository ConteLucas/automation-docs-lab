# Log Standardization & Click Optimization

## Overview
This document describes the improvements made to standardize logging format and optimize the click behavior.

---

## Changes Implemented

### 1. Standardized Log Format ✅

**Problem**: Logs used emojis and inconsistent prefixes (✅, ❌, ⚠️, 🎯, etc.), making them harder to parse programmatically.

**Solution**: Replaced all emoji-based log prefixes with standard log levels: `[INFO]`, `[WARN]`, `[ERROR]`.

**Before**:
```
✅ Accessibility service available
❌ Failed to dispatch gesture
⚠️ First click failed
🎯 Dispatching gesture
```

**After**:
```
[INFO] Accessibility service available
[ERROR] Failed to dispatch gesture
[WARN] First click failed
[INFO] Dispatching gesture
```

**Benefits**:
- Easier to filter/grep logs by level
- More professional appearance
- Better compatibility with log parsing tools
- Consistent with industry standards

---

### 2. Removed Retry Click ✅

**Problem**: The login click had a retry mechanism that attempted a second click at center position (640, 360) even when the first click succeeded via Accessibility Service.

**Issue in Logs**:
```
02-27 14:46:50.932  I  [INFO] Click executed via Accessibility at (1238, 1125)
02-27 14:46:51.905  I  Executing click at (640, 360)  <-- Unnecessary
02-27 14:46:57.047  I  [INFO] Click executed via Accessibility at (640, 360)  <-- Unnecessary
```

**Solution**: Removed the retry logic. The bot now performs a single click attempt at the configured position.

**Before**:
```kotlin
// Try clicking on login button (attempt 1)
onLog?.invoke("[INFO] Attempt 1: Clicking at configured position")
var clickSuccess = screenClicker.click(GameCoordinate.LOGIN_BTN_ENTER, onLog)

// If first attempt failed, try center of screen (attempt 2)
if (!clickSuccess) {
    onLog?.invoke("[WARN] First click failed, trying center position...")
    delay(1000)
    onLog?.invoke("[INFO] Attempt 2: Clicking at screen center (640, 360)")
    clickSuccess = screenClicker.clickAt(640, 360, onLog)
}
```

**After**:
```kotlin
// Click on login button
onLog?.invoke("[INFO] Clicking at configured position")
val clickSuccess = screenClicker.click(GameCoordinate.LOGIN_BTN_ENTER, onLog)
```

---

### 3. Draggable Expanded Window (Fixed) ✅

**Problem**: The expanded floating window was not draggable despite the code implementation.

**Root Cause**: The touch listener was attached to the `headerContainer`, but the buttons inside were intercepting touch events.

**Solution**: Moved the touch listener from `headerContainer` to `tvTitle` (the "DDT Bot" text), which has no child views to interfere.

**Implementation**:
```kotlin
// Get reference to title TextView
val tvTitle = expandedView?.findViewById<android.widget.TextView>(R.id.tvTitle)

// Add touch listener to title only (not entire header)
tvTitle?.setOnTouchListener { _, event ->
    when (event.action) {
        MotionEvent.ACTION_DOWN -> {
            initialX = expandedParams?.x ?: 0
            initialY = expandedParams?.y ?: 0
            initialTouchX = event.rawX
            initialTouchY = event.rawY
            Timber.d("[INFO] Float drag started at (${event.rawX}, ${event.rawY})")
            true
        }
        
        MotionEvent.ACTION_MOVE -> {
            val deltaX = (initialTouchX - event.rawX).toInt()
            val deltaY = (event.rawY - initialTouchY).toInt()
            
            expandedParams?.x = initialX + deltaX
            expandedParams?.y = initialY + deltaY
            
            windowManager?.updateViewLayout(expandedView, expandedParams)
            true
        }
        
        MotionEvent.ACTION_UP -> {
            Timber.d("[INFO] Float drag ended at position (${expandedParams?.x}, ${expandedParams?.y})")
            true
        }
        
        else -> false
    }
}
```

**Usage**: 
- Click and hold on the **"DDT Bot" title text**
- Drag to any position
- The buttons (⏸, ✕, ─) remain clickable

---

## Files Modified

### 1. `app/src/main/java/com/automation/bot/domain/usecases/MenuLoginUseCase.kt`
- **Changed**: Standardized all logs to `[INFO]`, `[WARN]`, `[ERROR]`
- **Changed**: Removed retry click logic (second attempt at 640, 360)
- **Changed**: Simplified success/failure handling

### 2. `app/src/main/java/com/automation/bot/automation/ScreenClicker.kt`
- **Changed**: Standardized all logs across all methods
- **Changed**: Updated `tryAccessibilityClick()` logs
- **Changed**: Updated `tryAdbClick()` logs

### 3. `app/src/main/java/com/automation/bot/domain/usecases/ScreenValidator.kt`
- **Changed**: Standardized all logs in `validateScreen()`
- **Changed**: Standardized all logs in `validateScreenWithRetry()`

### 4. `app/src/main/java/com/automation/bot/ui/FloatingLogWindow.kt`
- **Fixed**: Changed touch listener from `headerView` to `tvTitle`
- **Added**: Debug logs for drag start/end positions

---

## Log Level Guidelines

### [INFO]
Use for normal operation messages:
- Starting operations
- Successful actions
- Progress updates
- Status changes

**Examples**:
```
[INFO] Starting login screen validation...
[INFO] Click executed via Accessibility at (1238, 1125)
[INFO] Waiting for screen to fully load...
```

### [WARN]
Use for recoverable issues or fallback scenarios:
- Service not available (but fallback exists)
- Retries
- Unexpected but non-critical situations

**Examples**:
```
[WARN] Accessibility service not available
[WARN] First click failed, trying ADB fallback...
[WARN] Screen validation failed after 5 attempts
```

### [ERROR]
Use for failures that prevent operation:
- Click failures (no retry available)
- Critical service errors
- Unrecoverable exceptions

**Examples**:
```
[ERROR] Failed to click login button
[ERROR] ADB click failed with exit code: 255
[ERROR] Accessibility click exception: null pointer
```

---

## Testing

### Test Standardized Logs
1. Run `./watch-logcat.sh`
2. Start the bot
3. Verify all logs use `[INFO]`, `[WARN]`, or `[ERROR]` prefixes
4. No emojis should appear in logs

### Test Single Click (No Retry)
1. Start bot
2. Wait for login screen validation
3. Observe only ONE click at (1238, 1125)
4. NO second click at (640, 360) should occur

### Test Draggable Window
1. Expand floating window
2. Click and hold on "DDT Bot" text
3. Drag to different position
4. Verify window moves smoothly
5. Test that buttons (⏸, ✕, ─) still work

---

## Expected Log Output

```
[INFO] Starting login screen validation...
[INFO] Waiting screenshot (101)
[INFO] Attempt 1/5 for screen (101)
[INFO] Validating screen: Main login screen
[WARN] Failed to capture screenshot - using mock
[INFO] Screen matched (101) - confidence: 100.00%
[INFO] Login screen detected! Confidence: 100.00%
[INFO] Waiting for screen to fully load...
[INFO] This gives time for animations and elements to appear
[INFO] 7 seconds remaining...
[INFO] 4 seconds remaining...
[INFO] Screen should be fully loaded now
[INFO] Clicking at configured position
[INFO] Click coordinate (LOGIN_BTN_ENTER) at X:1238 Y:1125
[INFO] Executing click at (1238, 1125)
[INFO] Accessibility service available
[INFO] Created gesture path at (1238, 1125)
[INFO] Dispatching gesture...
[INFO] Waiting for gesture...
[INFO] Click executed via Accessibility at (1238, 1125)
[INFO] Login button clicked successfully
```

---

## Migration Notes

### For Future Log Parsing
If you plan to parse logs programmatically, use this pattern:

```bash
# Filter by log level
grep "\[INFO\]" bot_log.txt
grep "\[ERROR\]" bot_log.txt
grep "\[WARN\]" bot_log.txt

# Count errors
grep -c "\[ERROR\]" bot_log.txt

# Extract click coordinates
grep "Click executed" bot_log.txt | grep -oE "\([0-9]+, [0-9]+\)"
```

### For Python Log Analysis
```python
import re

def parse_log_level(line):
    match = re.search(r'\[(INFO|WARN|ERROR)\]', line)
    return match.group(1) if match else None

def extract_click_coords(line):
    match = re.search(r'at \((\d+), (\d+)\)', line)
    if match:
        return (int(match.group(1)), int(match.group(2)))
    return None
```

---

## Troubleshooting

### Logs Still Showing Emojis
- Ensure app was rebuilt after code changes
- Clear app data: `adb shell pm clear com.automation.bot`
- Reinstall: `./run.sh`

### Window Not Draggable
- Try dragging the **"DDT Bot" text specifically**, not the buttons
- If buttons are blocking, increase font size of title in XML
- Check logcat for drag start/end messages

### Click Still Retrying
- Verify `MenuLoginUseCase.kt` was updated
- Check line 54-55 for single click (no `if (!clickSuccess)` block)
- Rebuild and reinstall

---

**Last Updated**: 2026-02-15  
**Version**: 1.3.0
