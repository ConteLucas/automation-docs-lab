# 🔧 Fix: Device Not Showing in Floating Window

**Data**: 2026-02-27  
**Status**: ✅ FIXED

---

## 🐛 Problema

O device name não aparecia no floating window mesmo sendo chamado `setDevice()` na `MainActivity`.

```
Device: --  ← Ficava assim (nunca mudava)
```

---

## 🔍 Causa Raiz

**Ordem de execução**:

```
1. MainActivity.onCreate()
   └─> initializeViewModel()
       └─> floatingLog.setDevice("emulator-5554")  ← Chamado aqui
           └─> tvDevice?.text = "emulator-5554"
               └─> tvDevice == null  ❌ (window ainda não expandido!)

2. Usuário clica no ícone floating
   └─> expand()
       └─> tvDevice = findViewById(R.id.tvDevice)  ← TextView criado aqui
           └─> Mas o valor já foi "setado" antes e perdido!
```

**Problema**: `setDevice()` era chamado **ANTES** do floating window ser expandido, então `tvDevice` era `null` e o valor era perdido.

---

## ✅ Solução

**Armazenar valores** e **aplicá-los quando expandir**:

### 1. Adicionar variáveis de armazenamento

```kotlin
class FloatingLogWindow(private val context: Context) {
    
    // TextView references (null when collapsed)
    private var tvLogin: TextView? = null
    private var tvLevel: TextView? = null
    private var tvServer: TextView? = null
    private var tvDevice: TextView? = null
    
    // ✅ NOVO: Stored data (applied when expanded)
    private var storedAccount: String = "accxpto"
    private var storedLevel: String = "--"
    private var storedServer: String = "--"
    private var storedDevice: String = "--"
}
```

### 2. Atualizar métodos set*() para armazenar valores

```kotlin
fun setDevice(deviceName: String) {
    storedDevice = deviceName  // ✅ Armazena o valor
    tvDevice?.text = deviceName  // Aplica se TextView existir
}

fun setAccount(accountName: String) {
    storedAccount = accountName
    tvLogin?.text = accountName
}

fun setLevel(level: String) {
    storedLevel = level
    tvLevel?.text = level
}

fun setServer(serverName: String) {
    storedServer = serverName
    tvServer?.text = serverName
}
```

### 3. Aplicar valores armazenados ao expandir

```kotlin
private fun expand() {
    // ... create views ...
    
    tvLogin = expandedView?.findViewById(R.id.tvLogin)
    tvLevel = expandedView?.findViewById(R.id.tvLevel)
    tvServer = expandedView?.findViewById(R.id.tvServer)
    tvDevice = expandedView?.findViewById(R.id.tvDevice)
    
    // ✅ NOVO: Apply stored values to UI
    tvLogin?.text = storedAccount
    tvLevel?.text = storedLevel
    tvServer?.text = storedServer
    tvDevice?.text = storedDevice
    
    // ... rest of expand logic ...
}
```

---

## 🔄 Fluxo Corrigido

```
1. MainActivity.onCreate()
   └─> floatingLog.setDevice("emulator-5554")
       └─> storedDevice = "emulator-5554"  ✅ Armazenado!
       └─> tvDevice?.text = ... (tvDevice == null, ignora)

2. Floating window aparece (collapsed)
   └─> Ícone pequeno visível
   └─> tvDevice ainda não existe

3. Usuário clica no ícone
   └─> expand()
       ├─> tvDevice = findViewById(R.id.tvDevice)  ✅ TextView criado
       └─> tvDevice?.text = storedDevice  ✅ Valor aplicado!
           └─> Device: emulator-5554  ✅ APARECE!
```

---

## 📊 Antes vs Depois

### ❌ ANTES:

```kotlin
// MainActivity chama
floatingLog.setDevice("emulator-5554")

// FloatingLogWindow.setDevice()
fun setDevice(deviceName: String) {
    tvDevice?.text = deviceName  // tvDevice == null, valor perdido!
}

// Usuário expande float
private fun expand() {
    tvDevice = findViewById(R.id.tvDevice)
    // ❌ Nada é aplicado, fica "--"
}
```

**Resultado**: `Device: --`

---

### ✅ DEPOIS:

```kotlin
// MainActivity chama
floatingLog.setDevice("emulator-5554")

// FloatingLogWindow.setDevice()
fun setDevice(deviceName: String) {
    storedDevice = deviceName  // ✅ Armazenado!
    tvDevice?.text = deviceName  // tvDevice == null, mas ok
}

// Usuário expande float
private fun expand() {
    tvDevice = findViewById(R.id.tvDevice)
    tvDevice?.text = storedDevice  // ✅ Aplica valor armazenado!
}
```

**Resultado**: `Device: emulator-5554` ✅

---

## 🧪 Como Testar

1. **Build e Install**:
```bash
./run/clean-install.sh emulator-5556
```

2. **Abrir app**:
- Floating window aparece (collapsed)

3. **Expandir float**:
- Clicar no ícone

4. **Verificar dados**:
```
Login: accxpto
Runtime: 00:00:05
Level: --
Server: --
Device: emulator-5556  ← ✅ DEVE APARECER AGORA!
```

---

## 🎯 Benefícios

### ✅ Funciona com dados setados antes de expandir
- `setDevice()` chamado na `onCreate()` ✅
- `setAccount()` chamado antes de show ✅
- `setLevel()` via OCR durante execução ✅
- `setServer()` via OCR durante execução ✅

### ✅ Funciona com dados setados durante execução
- Valores podem ser atualizados a qualquer momento
- Se expandido: aplica diretamente no TextView
- Se collapsed: armazena para aplicar quando expandir

### ✅ Persistência entre collapse/expand
- Usuário colapsa o float
- Valores ficam armazenados
- Ao expandir novamente, valores reaparecem

---

## 📝 Arquivos Modificados

### FloatingLogWindow.kt

**Linhas adicionadas**:
```kotlin
// Storage variables (linha ~69)
private var storedAccount: String = "accxpto"
private var storedLevel: String = "--"
private var storedServer: String = "--"
private var storedDevice: String = "--"

// Apply in expand() (linha ~230)
tvLogin?.text = storedAccount
tvLevel?.text = storedLevel
tvServer?.text = storedServer
tvDevice?.text = storedDevice

// Update set methods (linhas ~444-479)
fun setDevice(deviceName: String) {
    storedDevice = deviceName
    tvDevice?.text = deviceName
}
// ... similar for setAccount, setLevel, setServer
```

---

## 🔍 Edge Cases Cobertos

### 1. setDevice() chamado antes de show()
```kotlin
val floatingLog = FloatingLogWindow(context)
floatingLog.setDevice("emulator-5554")  // Armazenado
floatingLog.show()  // Collapsed, tvDevice == null
// Usuário expande → valor aplicado ✅
```

### 2. setDevice() chamado depois de expand()
```kotlin
floatingLog.show()
// Usuário expande
floatingLog.setDevice("emulator-5554")
// Aplicado imediatamente em tvDevice ✅
```

### 3. setDevice() chamado múltiplas vezes
```kotlin
floatingLog.setDevice("emulator-5554")
floatingLog.setDevice("emulator-5556")  // Última chamada vence
// Usuário expande → "emulator-5556" ✅
```

### 4. Collapse e re-expand
```kotlin
// Expandido com Device: emulator-5554
// Usuário colapsa
// Usuário expande novamente
// Device: emulator-5554 ainda aparece ✅
```

---

## ✅ Conclusão

**Problema**: Device não aparecia porque `setDevice()` era chamado antes do TextView existir.

**Solução**: Armazenar valores em variáveis e aplicá-los ao expandir o window.

**Resultado**: Device name agora aparece corretamente no floating window! 📱✅

---

**Mesmo padrão aplicado para**:
- ✅ Account (login)
- ✅ Level
- ✅ Server
- ✅ Device

**Todos agora funcionam corretamente!** 🎉
