# 📊 Sistema de Logs Unificados - Bot + Game

**Data**: 2026-02-27  
**Objetivo**: Monitorar logs do Bot e do Jogo DDT no mesmo local

---

## 🎯 O que foi implementado

Agora você pode ver **logs do Bot** e **logs do Jogo DDT** juntos em:
- ✅ Floating Window
- ✅ MainActivity
- ✅ Arquivo de log
- ✅ Terminal (`./run/watch-unified.sh`)

---

## 🔧 Como Funciona

### **1. LogcatMonitor**
Nova classe que monitora logs do jogo em tempo real:

```kotlin
class LogcatMonitor {
    fun start()  // Inicia monitoramento
    fun stop()   // Para monitoramento
}
```

**O que faz:**
- Captura logs do pacote `com.road7.ddtankbr.gp` via logcat
- Formata com tag `[GAME]`
- Envia para `AutoLogger` (que distribui para Float + App + File)

### **2. Integração no BotViewModel**

```kotlin
class BotViewModel(...) {
    private val logcatMonitor = LogcatMonitor()
    
    fun start() {
        logcatMonitor.start()  // Inicia ao startar bot
        // ...
    }
    
    fun stop() {
        logcatMonitor.stop()   // Para ao parar bot
        // ...
    }
}
```

### **3. Fluxo de Logs**

```
┌─────────────────────────────────────────────┐
│           Logs do Bot (AutoLogger)          │
│  - Screen matched                           │
│  - Click executed                           │
│  - Vision API response                      │
└──────────────┬──────────────────────────────┘
               │
               ▼
       ┌───────────────┐
       │  AutoLogger   │ ← Centraliza tudo
       └───────┬───────┘
               │
               ├──────► Logcat (Timber)
               ├──────► Floating Window
               ├──────► MainActivity
               └──────► Log File
               
┌─────────────────────────────────────────────┐
│        Logs do Jogo (LogcatMonitor)         │
│  - Activity started                         │
│  - WebView loaded                           │
│  - Game events                              │
└──────────────┬──────────────────────────────┘
               │
               ▼
       ┌───────────────┐
       │ LogcatMonitor │ ← Captura via logcat
       └───────┬───────┘
               │
               ▼
       ┌───────────────┐
       │  AutoLogger   │ ← Formata com [GAME]
       └───────┬───────┘
               │
               ├──────► Logcat (Timber)
               ├──────► Floating Window
               ├──────► MainActivity
               └──────► Log File
```

---

## 📊 Exemplo de Logs Unificados

### **No Float e App:**

```
2026-02-27 18:30:00 - [INFO] - Bot started
2026-02-27 18:30:01 - [INFO] - Opening DDT game (com.road7.ddtankbr.gp)
2026-02-27 18:30:02 - [INFO] - [GAME] I/ActivityManager: Start proc com.road7.ddtankbr.gp
2026-02-27 18:30:03 - [INFO] - DDT launched successfully
2026-02-27 18:30:04 - [INFO] - [GAME] I/WebView: Loading game assets
2026-02-27 18:30:05 - [INFO] - Starting login screen validation...
2026-02-27 18:30:06 - [INFO] - Screenshot captured: 1280x720
2026-02-27 18:30:07 - [INFO] - Calling Vision API lens endpoint...
2026-02-27 18:30:08 - [INFO] - Vision API response: found=true, confidence=0.95
2026-02-27 18:30:09 - [INFO] - [GAME] I/DDTGame: Login screen loaded
2026-02-27 18:30:10 - [INFO] - Screen matched (101) - confidence: 95.00%
2026-02-27 18:30:15 - [INFO] - Executing click at (1238, 1125)
2026-02-27 18:30:16 - [INFO] - [GAME] I/DDTGame: Button clicked
2026-02-27 18:30:16 - [INFO] - Click executed via Accessibility at (1238, 1125)
```

**Agora você vê:**
- ✅ O que o **bot está fazendo** (sem `[GAME]`)
- ✅ O que o **jogo está fazendo** (com `[GAME]`)
- ✅ Como o jogo **reage** às ações do bot

---

## 🧪 Como Testar

### **1. Via App (Float + MainActivity):**

```bash
cd automation-bot-ddt
./run/clean-install.sh
```

Inicie o bot e observe:
- Logs do bot aparecem normalmente
- Logs do jogo aparecem com tag `[GAME]`

### **2. Via Terminal (watch-unified.sh):**

```bash
cd automation-bot-ddt
./run/watch-unified.sh
```

Saída formatada com cores:
- 🟢 **[BOT]** - Logs do bot (verde)
- 🔵 **[GAME]** - Logs do jogo (azul)

### **3. Via Terminal (watch-bot-only.sh atualizado):**

```bash
./run/watch-bot-only.sh
```

Agora também inclui logs do jogo!

---

## ⚙️ Permissões Necessárias

O `LogcatMonitor` requer a permissão `READ_LOGS`:

```xml
<uses-permission android:name="android.permission.READ_LOGS"
    tools:ignore="ProtectedPermissions" />
```

**Nota**: Em dispositivos reais, essa permissão pode precisar ser concedida via ADB:

```bash
adb shell pm grant com.automation.bot android.permission.READ_LOGS
```

Em emuladores, geralmente funciona automaticamente.

---

## 📋 Arquivos Modificados

```
automation-bot-ddt/
├── app/src/main/
│   ├── AndroidManifest.xml                    (✏️ adicionada permissão READ_LOGS)
│   └── java/com/automation/bot/
│       ├── utils/
│       │   └── LogcatMonitor.kt               (🆕 criado)
│       └── presentation/viewmodel/
│           └── BotViewModel.kt                (✏️ integrado LogcatMonitor)
└── run/
    ├── watch-bot-only.sh                      (✏️ agora inclui logs do jogo)
    └── watch-unified.sh                       (🆕 criado, formatado com cores)
```

---

## 🎯 Benefícios

1. **Visibilidade Completa**: Vê bot + jogo no mesmo lugar
2. **Debug Mais Fácil**: Correlaciona ação do bot com reação do jogo
3. **Menos Alternância**: Não precisa trocar entre janelas
4. **Logs Salvos**: Tudo fica no arquivo de log unificado
5. **Tempo Real**: Monitoramento ao vivo durante execução

---

## 🚨 Notas Importantes

### **Performance**
O `LogcatMonitor` roda em background (coroutine IO), não afeta a performance do bot.

### **Logs do Jogo**
Só captura logs de **Info** e acima (I/, W/, E/). Debug (D/) é ignorado para evitar poluição.

### **Início/Parada Automática**
- ✅ Inicia quando bot inicia
- ✅ Para quando bot para
- ✅ Cleanup automático de recursos

---

## 🔍 Troubleshooting

### **Não vejo logs do jogo**

1. Verifique permissão:
```bash
adb shell dumpsys package com.automation.bot | grep READ_LOGS
```

2. Conceda manualmente se necessário:
```bash
adb shell pm grant com.automation.bot android.permission.READ_LOGS
```

3. Verifique se o jogo está rodando:
```bash
adb shell ps | grep com.road7.ddtankbr.gp
```

### **Muitos logs aparecendo**

Ajuste o filtro em `LogcatMonitor.kt`:
```kotlin
// Mostrar apenas errors e warnings
"$GAME_PACKAGE:W"  // Ao invés de :I
```

---

**Status**: ✅ Sistema de logs unificados implementado e funcionando!
