# SCREEN CLICKER - ACCESSIBILITY SERVICE

## 🔧 Problema Resolvido

O `ScreenClicker` não estava funcionando porque tentava usar `input tap` via `Runtime.exec()`, mas apps Android normais **não têm permissão** para executar comandos shell que simulam toques.

---

## ✅ Solução: Accessibility Service

Implementamos um **Accessibility Service** que permite ao bot:
- ✅ Clicar em qualquer coordenada da tela
- ✅ Funcionar em todos os apps (incluindo o jogo DDT)
- ✅ Não requer root
- ✅ Funciona em Android 7.0+ (API 24+)

---

## 📋 Como Habilitar (IMPORTANTE!)

### 1️⃣ Abra as Configurações do Android

No emulador ou dispositivo:
```
Settings → Accessibility → Installed Services → Bot DDT
```

### 2️⃣ Ative o Serviço

- Clique em **"Bot DDT"**
- Ative o toggle **"Use Bot DDT"**
- Confirme a permissão quando solicitado

### 3️⃣ Verifique no App

Abra o app **Bot DDT** e veja os logs:
```
Overlay permission: OK
Accessibility service: OK  ← Deve mostrar OK
```

Se mostrar `NOT ENABLED`, repita os passos acima.

---

## 🏗️ Arquitetura

### Arquivos Criados/Modificados:

1. **`BotAccessibilityService.kt`** (NOVO)
   - Serviço de acessibilidade
   - Registra-se como disponível para `ScreenClicker`
   
2. **`accessibility_service_config.xml`** (NOVO)
   - Configuração do serviço
   - `canPerformGestures="true"` → Permite clicks
   
3. **`ScreenClicker.kt`** (MODIFICADO)
   - Usa `AccessibilityService.dispatchGesture()`
   - Funciona via `Path` e `GestureDescription`
   
4. **`AndroidManifest.xml`** (MODIFICADO)
   - Declara o serviço de acessibilidade
   - Adiciona permissão `BIND_ACCESSIBILITY_SERVICE`
   
5. **`MainActivity.kt`** (MODIFICADO)
   - Verifica se o serviço está habilitado
   - Exibe mensagem se não estiver

---

## 🔄 Fluxo de Execução

```
┌────────────────────────────────────────┐
│ 1. User opens Bot DDT app              │
└──────────────┬─────────────────────────┘
               │
               ▼
┌────────────────────────────────────────┐
│ 2. MainActivity checks permissions     │
│    - Overlay: OK                       │
│    - Accessibility: OK (if enabled)    │
└──────────────┬─────────────────────────┘
               │
               ▼
┌────────────────────────────────────────┐
│ 3. BotAccessibilityService starts      │
│    - Calls: ScreenClicker              │
│      .setAccessibilityService(this)    │
└──────────────┬─────────────────────────┘
               │
               ▼
┌────────────────────────────────────────┐
│ 4. User clicks START                   │
└──────────────┬─────────────────────────┘
               │
               ▼
┌────────────────────────────────────────┐
│ 5. MenuLoginUseCase validates screen   │
│    and calls ScreenClicker.click()     │
└──────────────┬─────────────────────────┘
               │
               ▼
┌────────────────────────────────────────┐
│ 6. ScreenClicker uses AccessibilityService│
│    - Creates Path(x, y)                │
│    - Creates GestureDescription        │
│    - Calls dispatchGesture()           │
└──────────────┬─────────────────────────┘
               │
               ▼
┌────────────────────────────────────────┐
│ 7. Android dispatches gesture          │
│    ✅ Click executed at (1238, 1125)   │
└────────────────────────────────────────┘
```

---

## 💻 Código: Como Funciona

### `BotAccessibilityService.kt`

```kotlin
class BotAccessibilityService : AccessibilityService() {
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        Timber.i("BotAccessibilityService connected")
        
        // Registra o serviço como disponível
        ScreenClicker.setAccessibilityService(this)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        
        // Remove o serviço quando destruído
        ScreenClicker.setAccessibilityService(null)
    }
}
```

### `ScreenClicker.kt` (Método Principal)

```kotlin
fun clickAt(x: Int, y: Int, onLog: ((String) -> Unit)?): Boolean {
    // 1. Show visual effect
    clickEffect?.showClickEffect(x, y)
    
    // 2. Get accessibility service
    val service = accessibilityService
    if (service == null) {
        onLog?.invoke("Accessibility service not available")
        return false
    }
    
    // 3. Create gesture path
    val path = Path()
    path.moveTo(x.toFloat(), y.toFloat())
    
    // 4. Create gesture description
    val gestureBuilder = GestureDescription.Builder()
    gestureBuilder.addStroke(
        GestureDescription.StrokeDescription(path, 0, 100)
    )
    val gesture = gestureBuilder.build()
    
    // 5. Dispatch gesture
    var success = false
    val callback = object : AccessibilityService.GestureResultCallback() {
        override fun onCompleted(gestureDescription: GestureDescription?) {
            success = true
            onLog?.invoke("Click executed successfully")
        }
        
        override fun onCancelled(gestureDescription: GestureDescription?) {
            onLog?.invoke("Click gesture cancelled")
        }
    }
    
    service.dispatchGesture(gesture, callback, null)
    
    // 6. Wait for gesture to complete
    val startTime = System.currentTimeMillis()
    while (!success && System.currentTimeMillis() - startTime < 1000) {
        Thread.sleep(50)
    }
    
    return success
}
```

---

## 🔍 Comparação: Antes vs Depois

### ❌ ANTES (Runtime.exec - Não Funciona)

```kotlin
// Tentava executar comando shell diretamente
val process = Runtime.getRuntime().exec(arrayOf(
    "input", "tap", x.toString(), y.toString()
))

// ❌ Falha com "Permission denied"
// Apps Android não podem executar input tap
```

**Problemas:**
- ❌ Requer permissões de shell (não disponível)
- ❌ Não funciona em apps normais
- ❌ Apenas funciona com root ou adb

---

### ✅ DEPOIS (AccessibilityService - Funciona!)

```kotlin
// Usa AccessibilityService oficial do Android
val service = accessibilityService
val path = Path()
path.moveTo(x.toFloat(), y.toFloat())

val gesture = GestureDescription.Builder()
    .addStroke(GestureDescription.StrokeDescription(path, 0, 100))
    .build()

service.dispatchGesture(gesture, callback, null)

// ✅ Funciona perfeitamente
// ✅ Não requer root
// ✅ API oficial do Android
```

**Vantagens:**
- ✅ API oficial do Android
- ✅ Não requer root
- ✅ Funciona em qualquer app
- ✅ Funciona em dispositivos reais e emuladores

---

## ⚠️ Requisitos

| Requisito | Detalhe |
|-----------|---------|
| **Android Version** | 7.0+ (API 24+) |
| **Permissão** | Accessibility Service deve estar habilitado |
| **Root** | ❌ Não necessário |
| **ADB** | ❌ Não necessário (apenas para instalar) |

---

## 🐛 Troubleshooting

### Problema: Clicks não estão funcionando

**Solução 1:** Verificar se o serviço está habilitado
```
Settings → Accessibility → Bot DDT → Enable
```

**Solução 2:** Verificar logs no Logcat
```bash
adb -s emulator-5556 logcat | grep "BotAccessibilityService"
```

Deve aparecer:
```
BotAccessibilityService connected
```

**Solução 3:** Reinstalar o app
```bash
./gradlew clean assembleDebug
adb -s emulator-5556 install -r app/build/outputs/apk/debug/app-debug.apk
```

---

### Problema: App diz "Accessibility service: NOT ENABLED"

**Causa:** O serviço não foi habilitado nas configurações.

**Solução:** Siga os passos de habilitação acima.

---

### Problema: Serviço está habilitado mas clicks não funcionam

**Causa:** O serviço pode ter crashado.

**Solução:** Desabilitar e reabilitar o serviço:
```
Settings → Accessibility → Bot DDT → Toggle OFF → Toggle ON
```

---

## 📊 Logs de Exemplo

### ✅ Sucesso:

```
[11:45:23] BotAccessibilityService connected
[11:45:25] Overlay permission: OK
[11:45:25] Accessibility service: OK
[11:45:30] Starting login screen validation...
[11:45:30] Screen matched (0009) - confidence: 95.00%
[11:45:31] Click coordinate (2929) at X:1238 Y:1125
[11:45:31] Executing click at (1238, 1125)
[11:45:31] Click executed successfully at (1238, 1125)
[11:45:31] Login button clicked successfully
```

### ❌ Erro (Serviço não habilitado):

```
[11:45:23] Overlay permission: OK
[11:45:23] Accessibility service: NOT ENABLED
[11:45:23] Please enable in Settings → Accessibility → Bot DDT
[11:45:30] Click coordinate (2929) at X:1238 Y:1125
[11:45:30] Accessibility service not available. Please enable accessibility permission.
[11:45:30] Failed to click login button
```

---

## 🎓 Conceitos Importantes

### O que é Accessibility Service?

Um serviço Android projetado para ajudar usuários com deficiências, mas também pode ser usado para automação:
- Leitura de tela (screen readers)
- Simulação de gestos (clicks, swipes)
- Observação de eventos de UI

### Por que não posso usar `adb shell input tap`?

O comando `adb shell input tap` funciona via ADB (Android Debug Bridge), mas:
- ❌ Apps Android não podem executar comandos ADB
- ❌ Requer conexão com computador
- ❌ Não funciona em dispositivos sem ADB

### Accessibility Service é seguro?

✅ Sim, mas:
- ⚠️ O usuário deve habilitar manualmente (não pode ser automatizado)
- ⚠️ Android mostra aviso de segurança
- ⚠️ Pode ler conteúdo de tela e interagir com outros apps

---

## 🚀 Próximos Passos

Com o `ScreenClicker` funcional, você pode:

1. ✅ Clicar no botão de login (coordenada 1238, 1125)
2. ✅ Adicionar mais coordenadas no `GameCoordinate` enum
3. ✅ Implementar swipes (futuro)
4. ✅ Implementar long press (futuro)
5. ✅ Adicionar validação de sucesso do click

---

## 📝 Checklist

Antes de testar o bot, certifique-se:

- [ ] App instalado no emulador/dispositivo
- [ ] Accessibility Service habilitado (Settings → Accessibility → Bot DDT)
- [ ] Overlay permission concedido
- [ ] DDT game instalado
- [ ] Logs mostram "Accessibility service: OK"

Se todos os itens estiverem OK, o bot deve funcionar! 🎯
