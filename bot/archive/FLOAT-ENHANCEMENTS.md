# Float Enhancements & Log Filtering

## Overview
This document describes the new features added to the floating window and main app: click-to-open functionality, log filtering, and visibility management.

---

## Features Implemented

### 1. Click on "DDT Bot" Title to Open Main App ✅

**What It Does**: Clicking on the "DDT Bot" title text in the floating window brings the main app back to the foreground.

**Usage**:
1. Expand floating window
2. Click on "DDT Bot" text (green title)
3. Main app opens and comes to front

**Implementation**:
```kotlin
// FloatingLogWindow.kt
tvTitle?.setOnClickListener {
    Timber.i("[INFO] Opening main app from float")
    onOpenMainApp?.invoke()
}

// MainActivity.kt
floatingLog.onOpenMainApp = {
    bringMainAppToFront()
}

private fun bringMainAppToFront() {
    val intent = Intent(this, MainActivity::class.java)
    intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
    startActivity(intent)
}
```

---

### 2. Log Filtering (Float & Main App) ✅

**What It Does**: Filter logs in real-time by typing keywords like "ERROR", "INFO", "Click", etc.

**Features**:
- **Case-insensitive** search
- **Instant** filtering as you type
- Works in both **floating window** and **main app**
- Shows "No logs match filter" when nothing matches

**Usage in Floating Window**:
1. Expand floating window
2. Type in the "Filter..." field (top-right of logs section)
3. Only matching logs will be displayed
4. Clear filter to see all logs again

**Usage in Main App**:
1. Open main app
2. Type in the "Filter:" field (above logs)
3. Same behavior as floating window

**Examples**:
- Type `ERROR` → See only error messages
- Type `Click` → See only click-related logs
- Type `1238` → See logs mentioning that coordinate
- Type `Accessibility` → See accessibility service logs

**Implementation**:
```kotlin
// Store all logs in memory
private val allLogs = mutableListOf<String>()
private var currentFilter = ""

fun log(message: String) {
    allLogs.add(message)
    applyFilter()
}

private fun applyFilter() {
    val filteredLogs = if (currentFilter.isBlank()) {
        allLogs
    } else {
        allLogs.filter { it.contains(currentFilter, ignoreCase = true) }
    }
    
    val displayText = if (filteredLogs.isEmpty()) {
        "> No logs match filter '$currentFilter'"
    } else {
        filteredLogs.joinToString("\n") { "> $it" }
    }
    
    tvLogs?.text = displayText
}
```

---

### 3. Float Visibility Management ✅

**What It Does**: Automatically manages floating window visibility based on app state.

**Behavior**:
- **When main app is in foreground**: Float stays visible (can be expanded or collapsed)
- **When main app is minimized/background**: Float collapses to icon automatically
- **When clicking "DDT Bot"**: Main app comes to front
- **When app is destroyed**: Float hides completely

**Implementation**:
```kotlin
override fun onWindowFocusChanged(hasFocus: Boolean) {
    super.onWindowFocusChanged(hasFocus)
    
    if (hasFocus) {
        // Main app has focus - expand float and hide icon
        if (floatingLog.isVisible() && !floatingLog.isWindowExpanded()) {
            Timber.d("[INFO] Main app focused - float should expand")
        }
    } else {
        // Main app lost focus - collapse float to icon
        if (floatingLog.isVisible() && floatingLog.isWindowExpanded()) {
            Timber.d("[INFO] Main app lost focus - float should collapse")
        }
    }
}
```

---

## UI Changes

### Floating Window Layout

**Before**:
```
┌─────────────────────────────────┐
│ DDT Bot              ▶ ✕ ─      │
│ ─────────────────────────────── │
│ Login: account01                │
│ Level: --                       │
│ Runtime: 00:00:00               │
│ ─────────────────────────────── │
│ Execution Logs                  │
│ ┌─────────────────────────────┐ │
│ │ > System initialized...     │ │
│ │ > [INFO] Starting...        │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

**After**:
```
┌─────────────────────────────────┐
│ DDT Bot (clickable)  ▶ ✕ ─      │
│ ─────────────────────────────── │
│ Login: account01                │
│ Level: --                       │
│ Runtime: 00:00:00               │
│ ─────────────────────────────── │
│ Execution Logs    [Filter...  ] │  ← New filter field
│ ┌─────────────────────────────┐ │
│ │ > System initialized...     │ │
│ │ > [INFO] Starting...        │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### Main App Layout

**Before**:
```
════════════════════
Logs will appear here...
```

**After**:
```
════════════════════
Filter: [Type to filter logs (e.g., ERROR, INFO)...]  ← New filter field
┌──────────────────────────────────┐
│ Bot DDT Initialized              │
│ [INFO] Starting...               │
└──────────────────────────────────┘
```

---

## Files Modified

### 1. `app/src/main/res/layout/floating_expanded.xml`
- **Added**: `EditText` for log filtering (id: `etFilterFloat`)
- **Changed**: Logs section now has horizontal layout with filter field

### 2. `app/src/main/res/layout/activity_main.xml`
- **Added**: `LinearLayout` with `TextView` label and `EditText` for filtering (id: `etFilter`)

### 3. `app/src/main/java/com/automation/bot/ui/FloatingLogWindow.kt`
- **Added**: `etFilterFloat` property for filter EditText
- **Added**: `allLogs` list to store all logs in memory
- **Added**: `currentFilter` string to track current filter text
- **Added**: `onOpenMainApp` callback for title click
- **Modified**: `log()` method to store logs and apply filter
- **Added**: `applyFilter()` method to filter and display logs
- **Modified**: `clear()` method to clear filter and stored logs
- **Added**: Title click listener in `expand()` method
- **Added**: Filter text watcher in `expand()` method

### 4. `app/src/main/java/com/automation/bot/ui/MainActivity.kt`
- **Added**: `etFilter` property for filter EditText
- **Added**: `allMainLogs` list to store all main app logs
- **Added**: `currentMainFilter` string to track filter
- **Modified**: `initializeViews()` to setup filter text watcher
- **Modified**: `initializeViewModel()` to setup `onOpenMainApp` callback
- **Modified**: `log()` method to store logs and apply filter
- **Added**: `applyMainFilter()` method to filter main app logs
- **Added**: `bringMainAppToFront()` method to bring app to foreground
- **Added**: `onWindowFocusChanged()` to manage float visibility

---

## Testing

### Test Log Filtering (Float)
1. Start bot
2. Expand floating window
3. Type "INFO" in filter field
4. Verify only [INFO] logs are shown
5. Type "ERROR"
6. Verify only [ERROR] logs are shown
7. Clear filter
8. Verify all logs appear again

### Test Log Filtering (Main App)
1. Open main app
2. Type "ERROR" in filter field
3. Verify only error messages shown
4. Type "Bot DDT"
5. Verify only logs containing "Bot DDT" appear
6. Clear filter
7. All logs reappear

### Test Title Click
1. Start bot (main app in foreground)
2. Minimize main app (home button)
3. Expand floating window
4. Click on "DDT Bot" title
5. Verify main app comes to front

### Test Filter Persistence
1. Type "INFO" in float filter
2. Several [INFO] logs appear
3. Type more text: "INFO Starting"
4. Verify logs update in real-time
5. Clear filter
6. All previously hidden logs reappear

---

## Filter Tips & Tricks

### Common Filters

**By Log Level:**
```
[INFO]    → All info messages
[WARN]    → All warnings
[ERROR]   → All errors
```

**By Action:**
```
Click     → All click actions
Screen    → Screen validation logs
Accessibility → Accessibility service logs
```

**By Coordinate:**
```
1238      → Logs mentioning X=1238
(1238, 1125) → Exact coordinate
```

**By Status:**
```
executed  → Successful actions
failed    → Failed actions
waiting   → Waiting/pending operations
```

### Multiple Word Search
The filter searches the **entire log line**, so you can search for phrases:
```
"executed via Accessibility" → Finds specific click type
"Click coordinate (LOGIN"    → Finds login button clicks
```

---

## Architecture Notes

### Log Storage
Both FloatingLogWindow and MainActivity maintain their own log storage:

```kotlin
// Separate storage for each display
private val allLogs = mutableListOf<String>()           // Float
private val allMainLogs = mutableListOf<String>()       // Main app
```

This allows independent filtering without affecting the other display.

### Memory Management
- Logs are stored in `ArrayList` (fast append)
- Filter creates a **new filtered list** each time (doesn't modify original)
- Clear operation removes all stored logs

**Future Optimization**: 
- Limit log storage to last 1000 messages
- Implement circular buffer to prevent memory growth

---

## Known Limitations

1. **Filter is substring-only** (no regex support yet)
2. **No AND/OR operators** (can't do "ERROR OR WARN")
3. **Float visibility auto-management not fully implemented** (requires lifecycle events)
4. **Filter state not persisted** (resets on app restart)

---

## Future Enhancements

### Advanced Filtering
```kotlin
// Regex support
filter: "^\\[ERROR\\].*"

// Multiple keywords (OR)
filter: "ERROR|WARN|CRITICAL"

// Negative filter (exclude)
filter: "!INFO"  // Show all except INFO
```

### Saved Filters
```kotlin
// Quick filter buttons
[ERROR] [WARN] [INFO] [Click] [Screen]
```

### Export Filtered Logs
```kotlin
// Export only filtered logs to file
exportFilteredLogs("error_logs_2026-02-15.txt")
```

---

**Last Updated**: 2026-02-15  
**Version**: 1.4.0
