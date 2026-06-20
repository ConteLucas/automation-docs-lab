# 💻 Development Guide

## 🎯 Como Adicionar Templates

### **1. Capturar Screenshot do DDTank**

```bash
# Com DDTank aberto no emulador
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ~/Desktop/
```

### **2. Recortar Elemento**

Use qualquer editor para recortar apenas o elemento desejado:
- Botão "Entrar" (200x60px)
- Campo de login
- Ícone do menu
- etc.

### **3. Salvar na Pasta Correta**

```
app/src/main/assets/templates/
├── ddtank/
│   ├── login/
│   │   ├── btn_entrar.png      👈 Aqui
│   │   └── campo_usuario.png
│   ├── menu/
│   └── game/
└── common/
```

**Copiar:**
```bash
cp ~/Desktop/botao_entrar.png \
   app/src/main/assets/templates/ddtank/login/btn_entrar.png
```

### **4. Nomenclatura**

Padrão: `[contexto]_[elemento]_[estado?].png`

**Exemplos:**
```
✅ login_btn_entrar.png
✅ menu_btn_jogar.png
✅ game_hp_bar_full.png
❌ botao.png (muito genérico)
❌ IMG_123.png (não descritivo)
```

### **5. Usar no Código**

```kotlin
val templateManager = TemplateManager(context)

// Listar templates
val templates = templateManager.listTemplates("ddtank/login")

// Carregar template
val templateBytes = templateManager.loadTemplateAsBytes("ddtank/login/btn_entrar.png")

// Enviar para Vision API
visionApiService.matchTemplate(
    screenshot = currentScreenshot,
    template = templateBytes,
    threshold = 0.8
)
```

---

## 🏗️ Arquitetura MVVM

### **Estrutura:**

```
ui/
├── MainActivity.kt           # Activity principal
└── viewmodels/              # ViewModels (futuro)

automation/
├── AppLauncher.kt           # Abre apps
├── ScreenCapture.kt         # Captura tela (futuro)
└── ActionExecutor.kt        # Toca, desliza (futuro)

templates/
└── TemplateManager.kt       # Gerencia templates

api/
└── VisionApiService.kt      # Comunica com Vision API

data/
└── ConfigRepository.kt      # SharedPreferences
```

---

## 📝 Criando Nova Funcionalidade

### **Exemplo: Implementar ScreenCapture**

**1. Criar classe:**
```kotlin
// automation/ScreenCapture.kt
class ScreenCapture(private val context: Context) {
    
    fun captureScreen(): ByteArray? {
        // Implementação
    }
}
```

**2. Usar na MainActivity:**
```kotlin
class MainActivity : AppCompatActivity() {
    
    private lateinit var screenCapture: ScreenCapture
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        screenCapture = ScreenCapture(this)
        
        // Capturar tela após 5 segundos
        Handler(Looper.getMainLooper()).postDelayed({
            val screenshot = screenCapture.captureScreen()
            log("Screenshot capturado: ${screenshot?.size} bytes")
        }, 5000)
    }
}
```

---

## 🔄 Fluxo de Desenvolvimento

### **1. Feature Branch**
```bash
git checkout -b feature/screen-capture
```

### **2. Desenvolver**
- Criar classes
- Adicionar testes (futuro)
- Documentar código

### **3. Testar**
```bash
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.automation.bot/.ui.MainActivity
adb logcat | grep BotApp
```

### **4. Commit**
```bash
git add .
git commit -m "feat: implement screen capture"
```

---

## 🧪 Testing

### **Manual Testing:**
```kotlin
// Adicionar logs na MainActivity
log("🧪 Testando ScreenCapture...")
val screenshot = screenCapture.captureScreen()
log("✅ Screenshot: ${screenshot?.size} bytes")
```

### **Via ADB:**
```bash
# Ver logs em tempo real
adb logcat -c && adb logcat | grep -E "🧪|✅|❌"
```

---

## 📊 Convenções de Código

### **Kotlin:**
- CamelCase para classes: `AppLauncher`
- camelCase para funções: `captureScreen()`
- UPPER_CASE para constantes: `DDTANK_PACKAGE`

### **Comentários:**
```kotlin
/**
 * Descrição da classe/função
 * 
 * @param context Contexto do Android
 * @return ByteArray do screenshot
 */
fun captureScreen(context: Context): ByteArray? {
    // Implementação
}
```

### **Logs:**
```kotlin
// Usar Timber
Timber.d("Debug message")
Timber.e(exception, "Error message")

// Ou log() na MainActivity para mostrar na tela
log("🎮 Iniciando DDTank...")
```

---

## 🔗 Integrações Futuras

### **Vision API:**
```kotlin
// api/VisionApiService.kt
interface VisionApiService {
    
    @POST("/match-template")
    suspend fun matchTemplate(
        @Body request: MatchRequest
    ): MatchResult
    
    @POST("/extract-text")
    suspend fun extractText(
        @Body request: OcrRequest
    ): OcrResult
}
```

### **Core API:**
```kotlin
// api/CoreApiService.kt
interface CoreApiService {
    
    @GET("/tasks")
    suspend fun getTasks(): List<Task>
    
    @POST("/tasks/{id}/complete")
    suspend fun completeTask(
        @Path("id") taskId: String,
        @Body result: TaskResult
    )
}
```

---

## 📦 Adicionando Dependências

### **build.gradle.kts:**
```kotlin
dependencies {
    // Exemplo: adicionar biblioteca de imagem
    implementation("com.github.bumptech.glide:glide:4.16.0")
}
```

### **Sincronizar:**
```bash
./gradlew --refresh-dependencies
```

---

## 🎨 UI Guidelines

- **Tema escuro** (fundo preto, texto verde)
- **Logs em tempo real** na tela
- **Feedback visual** (✅ ❌ 🎮 🚀)
- **Minimalista** (sem botões desnecessários)

---

## 🚀 Deploy (Futuro)

### **Release Build:**
```bash
./gradlew assembleRelease
```

### **Signing:**
```kotlin
// app/build.gradle.kts
android {
    signingConfigs {
        release {
            storeFile file("keystore.jks")
            storePassword "password"
            keyAlias "alias"
            keyPassword "password"
        }
    }
}
```

---

## 📚 Recursos

- [Android Developers](https://developer.android.com/)
- [Kotlin Docs](https://kotlinlang.org/docs/)
- [UIAutomator2](https://developer.android.com/training/testing/ui-automator)
- [Retrofit](https://square.github.io/retrofit/)
