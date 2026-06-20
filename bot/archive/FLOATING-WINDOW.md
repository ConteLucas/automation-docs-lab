# 🪟 Floating Log Window - How It Works

## 🎯 Problem

When the bot opens DDT, the game covers the bot's screen, making it impossible to see logs.

## ✅ Solution

**Floating Window** - A transparent overlay that displays logs on top of ANY app, including the game.

---

## 🏗️ Architecture

```
Bot opens DDT
    ↓
DDT goes to foreground (covers bot)
    ↓
Floating window stays on top
    ↓
You can see logs while playing!
```

---

## 📱 Visual Example

```
┌─────────────────────────────────┐
│  DDT Game (fullscreen)          │  👈 Game running
│                                 │
│  ┌───────────────────────┐     │
│  │ Bot DDT               │     │  👈 Floating window
│  │ ═════════════════     │     │      (on top!)
│  │ Bot DDT Initialized   │     │
│  │ Starting DDT...       │     │
│  │ DDT started!          │     │
│  │ Waiting for login...  │     │
│  └───────────────────────┘     │
│                                 │
│  [Game UI elements here]        │
│                                 │
└─────────────────────────────────┘
```

---

## 🔧 Implementation

### **1. Permission Required**

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
```

This permission allows the app to draw over other apps.

### **2. FloatingLogWindow Class**

```kotlin
class FloatingLogWindow(private val context: Context) {
    
    fun show() {
        // Creates overlay using WindowManager
        windowManager?.addView(floatingView, params)
    }
    
    fun log(message: String) {
        // Adds text to floating TextView
        tvFloatingLog?.text = "$currentText\n$message"
    }
    
    fun hide() {
        // Removes overlay
        windowManager?.removeView(floatingView)
    }
}
```

### **3. MainActivity Integration**

```kotlin
class MainActivity : AppCompatActivity() {
    
    private lateinit var floatingLog: FloatingLogWindow
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize
        floatingLog = FloatingLogWindow(this)
        
        // Check permission
        if (canDrawOverlays()) {
            openGame()
        } else {
            requestOverlayPermission()
        }
    }
    
    private fun openGame() {
        // Show floating window BEFORE opening game
        floatingLog.show()
        floatingLog.log("Opening DDT...")
        
        // Open game
        appLauncher.launch(DDTANK_PACKAGE)
        
        // Game opens and covers bot
        // But floating window stays on top!
        floatingLog.log("DDT started!")
    }
}
```

---

## 🔐 Permission Flow

### **First Run:**

```
1. Bot starts
   ↓
2. Checks: canDrawOverlays()?
   ↓
3. If NO → Request permission
   ↓
4. Shows system dialog:
   "Allow Bot DDT to display over other apps?"
   ↓
5. User clicks "Allow"
   ↓
6. Bot continues → Shows floating window
```

### **Subsequent Runs:**

```
1. Bot starts
   ↓
2. Checks: canDrawOverlays()?
   ↓
3. If YES → Directly shows floating window
   (No dialog needed!)
```

---

## 🎨 Customization

### **Position:**

```kotlin
// Top center (current)
params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL

// Bottom right
params.gravity = Gravity.BOTTOM or Gravity.RIGHT

// Center
params.gravity = Gravity.CENTER
```

### **Size:**

```kotlin
val params = WindowManager.LayoutParams(
    WindowManager.LayoutParams.MATCH_PARENT,  // Full width
    400,  // 400dp height
    // ...
)
```

### **Transparency:**

```xml
<!-- CardView background -->
app:cardBackgroundColor="#CC000000"
                          ^^
                          CC = 80% opacity (00 = transparent, FF = opaque)
```

---

## 🎯 Key Features

### **1. Non-Focusable**

```kotlin
WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
```

Allows game to receive touch events (you can play while window is visible).

### **2. Always On Top**

```kotlin
WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
```

Window stays above all apps.

### **3. Auto-scroll**

```kotlin
textView.post {
    val scrollView = textView.parent as? ScrollView
    scrollView?.fullScroll(View.FOCUS_DOWN)
}
```

Automatically scrolls to show latest logs.

---

## 🐛 Troubleshooting

### **"Permission denied" on Android 6+**

Check `Settings.canDrawOverlays()` first.

### **Window not showing**

```kotlin
// Check permission
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
    if (!Settings.canDrawOverlays(this)) {
        // Request permission
    }
}
```

### **Window covers game UI**

Adjust position or make it draggable:

```kotlin
floatingView?.setOnTouchListener { view, event ->
    // Implement drag functionality
}
```

---

## 📊 Comparison

| Method | Visible when game opens | Requires permission | Performance |
|--------|------------------------|--------------------| ------------|
| MainActivity TextView | ❌ No | ✅ No | ⚡ Fast |
| Floating Window | ✅ Yes | ⚠️ Yes | ⚡ Fast |
| Logcat only | ⚠️ Via ADB | ✅ No | ⚡ Fast |

---

## 🚀 Usage

```kotlin
// Show window
floatingLog.show()

// Add logs
floatingLog.log("Starting automation...")
floatingLog.log("Template found at (500, 800)")
floatingLog.log("Tapping button...")

// Clear logs
floatingLog.clear()

// Hide window
floatingLog.hide()
```

---

## 🎯 Next Steps

1. ✅ Floating window created
2. 🔜 Make window draggable
3. 🔜 Add minimize button
4. 🔜 Save position preference
5. 🔜 Add color-coded log levels (info/warning/error)

---

**Now you can see bot logs while playing DDT!** 🎮
