# Floating Window Improvements

## Overview
This document describes the improvements made to the floating window system to enhance usability and log visibility.

---

## Changes Implemented

### 1. Draggable Expanded Window ✅

**Problem**: The expanded floating window was fixed in position and couldn't be moved around the screen.

**Solution**: Added touch event handling to the header container, allowing users to drag the expanded window anywhere on screen.

**Implementation**:
```kotlin
// FloatingLogWindow.kt
headerView?.setOnTouchListener { view, event ->
    when (event.action) {
        MotionEvent.ACTION_DOWN -> {
            initialX = expandedParams?.x ?: 0
            initialY = expandedParams?.y ?: 0
            initialTouchX = event.rawX
            initialTouchY = event.rawY
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
            true
        }
        
        else -> false
    }
}
```

**Usage**: 
- Click and hold on the "DDT Bot" header
- Drag to any position on screen
- Release to fix position

---

### 2. Complete Log Visibility ✅

**Problem**: Some logs from `watch-logcat.sh` (especially from `ScreenClicker`) were not appearing in the floating window.

**Solution**: Ensured **all** log messages are routed through the `onLog` callback, not just `Timber`.

**Before**:
```kotlin
Timber.d("Accessibility service not available")  // Only in logcat
return false
```

**After**:
```kotlin
val msg = "❌ Accessibility service not available"
Timber.w(msg)        // In logcat
onLog?.invoke(msg)   // In floating window + file
return false
```

**Impact**: Now all diagnostic messages appear in:
1. **Logcat** (via `Timber`)
2. **Floating window** (via `onLog` → `floatingLog.log()`)
3. **MainActivity logs** (via `onLog` → `onMainLog`)
4. **Log files** (via `onLog` → `logFileManager.appendLog()`)

---

### 3. Increased Click Wait Time ✅

**Problem**: Click actions were happening too fast (5 seconds), not giving the game screen time to fully load.

**Solution**: Increased delay from 5 to **10 seconds** with progressive countdown logs.

**Implementation**:
```kotlin
// MenuLoginUseCase.kt
onLog?.invoke("⏳ Waiting for screen to fully load...")
onLog?.invoke("⏳ This gives time for animations and elements to appear")
delay(3000)
onLog?.invoke("⏳ 7 seconds remaining...")
delay(3000)
onLog?.invoke("⏳ 4 seconds remaining...")
delay(4000)
onLog?.invoke("✅ Screen should be fully loaded now")
```

**Future Enhancement**: This will be replaced by continuous Vision API validation, where the bot will poll until the target UI element is detected before clicking.

---

## Files Modified

### 1. `app/src/main/java/com/automation/bot/ui/FloatingLogWindow.kt`
- Added `expandedParams` and `headerView` properties
- Modified `expand()` to attach touch listener to header
- Updated `collapse()` and `hide()` to clean up new properties

### 2. `app/src/main/res/layout/floating_expanded.xml`
- Added `android:id="@+id/headerContainer"` to the header `RelativeLayout`

### 3. `app/src/main/java/com/automation/bot/automation/ScreenClicker.kt`
- Modified `tryAccessibilityClick()` to route **all** log messages through `onLog` callback
- Added error messages to floating window for better debugging

### 4. `app/src/main/java/com/automation/bot/domain/usecases/MenuLoginUseCase.kt`
- Increased click delay from 5s to 10s
- Added progressive countdown messages

---

## Testing

### Test Draggable Window
1. Open bot app
2. Start bot (floating icon appears)
3. Tap icon to expand window
4. Click and hold "DDT Bot" header
5. Drag to different position
6. Verify window moves smoothly

### Test Log Visibility
1. Run `./watch-logcat.sh` in terminal
2. Start bot
3. Observe logs in logcat
4. Expand floating window
5. Verify same logs appear in floating window in real-time

### Test Click Delay
1. Start bot
2. Wait for DDT game to open
3. Observe logs showing 10-second countdown
4. Verify click happens after full delay

---

## Architecture Notes

### Log Flow
```
Action/Event
    ↓
Timber.i() / Timber.w() / Timber.e()  →  Logcat
    ↓
onLog callback
    ↓
    ├─→ floatingLog.log()           →  Floating Window
    ├─→ onMainLog()                 →  MainActivity TextView
    └─→ logFileManager.appendLog()  →  /sdcard/Download/.../logs/
```

### Touch Event Handling
```
User touches header
    ↓
ACTION_DOWN: Save initial position + touch coords
    ↓
ACTION_MOVE: Calculate delta, update window position
    ↓
ACTION_UP: Finalize position
```

---

## Next Steps

1. **Vision API Integration**: Replace fixed 10-second delay with smart polling:
   ```kotlin
   // Future implementation
   while (!visionApi.detectElement("LOGIN_BUTTON")) {
       delay(1000)
       takeScreenshot()
   }
   ```

2. **Save Window Position**: Persist user's preferred floating window position:
   ```kotlin
   SharedPreferences.put("float_x", expandedParams.x)
   SharedPreferences.put("float_y", expandedParams.y)
   ```

3. **Gesture Improvements**: Add pinch-to-resize for floating window size adjustment

---

## Troubleshooting

### Window Not Draggable
- Ensure Accessibility Service is enabled
- Check `headerContainer` ID exists in XML layout
- Verify `expandedParams` is not null

### Logs Not Appearing in Float
- Confirm `onLog` callback is passed to all use cases
- Check `BotFactory` wiring for `logCallback`
- Verify floating window is expanded (collapsed state doesn't show logs)

### Click Too Fast/Slow
- Adjust delays in `MenuLoginUseCase.kt`
- Consider device performance (emulator vs real device)
- Wait for Vision API for dynamic timing

---

**Last Updated**: 2026-02-15  
**Version**: 1.2.0
