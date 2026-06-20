# 🔍 Monitoramento de Logs em Tempo Real

## 📋 Scripts Disponíveis

### 1️⃣ **watch-logcat.sh** (Recomendado)
Mostra **todos os logs técnicos** do bot via Logcat.

**Quando usar:**
- Debugar problemas técnicos
- Ver exceptions e erros
- Acompanhar fluxo completo de execução

**Como executar:**
```bash
./watch-logcat.sh
```

**O que mostra:**
```
BotViewModel: Bot started
LogFileManager: Log file created: /sdcard/Download/...
ScreenValidator: Waiting screenshot (101)
ScreenClicker: Executing click at (1238, 1125)
BotAccessibilityService: ✅ BotAccessibilityService connected
```

---

### 2️⃣ **watch-log-file.sh**
Mostra o **arquivo de log** que está sendo salvo no dispositivo.

**Quando usar:**
- Ver exatamente o que está sendo salvo no arquivo
- Acompanhar os logs "oficiais" do bot
- Verificar se os logs estão sendo escritos

**Como executar:**
```bash
./watch-log-file.sh
```

**O que mostra:**
```
═══════════════════════════════════════════════════
DDT BOT - EXECUTION LOG
═══════════════════════════════════════════════════
Start Time: 2026-02-27 04:30:15
Path: /sdcard/Download/automation-bot-ddt/logs/bot_log_2026-02-27_04-30-15.txt
═══════════════════════════════════════════════════

[2026-02-27 04:30:15] Bot started
[2026-02-27 04:30:17] Opening DDT game (com.road7.ddtankbr.gp)
[2026-02-27 04:30:20] Screen matched (101) - confidence: 95.00%
```

---

### 3️⃣ **watch-bot-only.sh**
Mostra apenas as **mensagens principais** do bot (sem logs técnicos).

**Quando usar:**
- Acompanhar a execução de forma simplificada
- Ver apenas ações principais (start, click, match)
- Apresentação ou demonstração

**Como executar:**
```bash
./watch-bot-only.sh
```

**O que mostra:**
```
Bot started
DDT launched successfully
Screen matched (101) - confidence: 95.00%
Click coordinate (2929) at X:1238 Y:1125
✅ Click executed successfully
```

---

## 🎯 Qual Usar?

| Script | Melhor Para | Nível de Detalhe |
|--------|-------------|------------------|
| `watch-logcat.sh` | Debug técnico, ver exceptions | ⭐⭐⭐⭐⭐ Muito alto |
| `watch-log-file.sh` | Ver logs oficiais salvos | ⭐⭐⭐ Médio |
| `watch-bot-only.sh` | Acompanhamento simples | ⭐⭐ Baixo |

---

## 🚀 Como Usar

### Passo 1: Abrir Terminal
```bash
cd /Users/luconte/Developer/learning/automation-learn/automation-bot-ddt
```

### Passo 2: Executar Script
```bash
./watch-logcat.sh
```

### Passo 3: Iniciar o Bot no Emulador
- Abra o app "Bot DDT"
- Clique em "START"
- Veja os logs aparecerem no terminal em tempo real!

### Passo 4: Parar Monitoramento
Pressione `Ctrl+C` no terminal

---

## 🔧 Comandos Úteis

### Ver Últimas 50 Linhas do Logcat
```bash
adb -s emulator-5556 logcat -d | tail -50
```

### Ver Apenas Erros
```bash
adb -s emulator-5556 logcat *:E
```

### Salvar Logs em Arquivo
```bash
adb -s emulator-5556 logcat > bot-debug.log
```

### Baixar Arquivo de Log do Dispositivo
```bash
adb -s emulator-5556 pull /sdcard/Download/automation-bot-ddt/logs/ ./device-logs/
```

---

## 📊 Exemplo de Saída Completa

```
🤖 Bot DDT - Live Logs via Logcat
==================================

Clearing old logs...
Monitoring Bot DDT logs...
Press Ctrl+C to stop

02-27 04:30:15.123 I BotViewModel: Bot started
02-27 04:30:15.124 I LogFileManager: 📝 Starting new log file...
02-27 04:30:15.125 I LogFileManager: 📂 Logs directory: /sdcard/Download/automation-bot-ddt/logs
02-27 04:30:15.126 I LogFileManager: ✅ Logs directory already exists
02-27 04:30:15.127 I LogFileManager: ✅ Log file created successfully
02-27 04:30:17.200 I StartBotUseCase: Opening DDT game (com.road7.ddtankbr.gp)
02-27 04:30:17.250 I AppLauncher: DDT launched successfully
02-27 04:30:20.100 I MenuLoginUseCase: Starting login screen validation...
02-27 04:30:20.150 I ScreenValidator: Waiting screenshot (101)
02-27 04:30:20.200 I ScreenValidator: Screen matched (101) - confidence: 95.00%
02-27 04:30:21.250 I ScreenClicker: Click coordinate (2929) at X:1238 Y:1125
02-27 04:30:21.300 I ScreenClicker: ✅ Accessibility service available
02-27 04:30:21.350 I ScreenClicker: 📍 Created gesture path at (1238, 1125)
02-27 04:30:21.400 I ScreenClicker: 🎯 Dispatching gesture...
02-27 04:30:21.500 I ScreenClicker: ✅ Click executed successfully at (1238, 1125)
```

---

## ⚠️ Troubleshooting

### Problema: "No log file found yet"
**Solução:** Inicie o bot primeiro, depois execute o script.

### Problema: Nenhum log aparece
**Solução:** 
```bash
# Verificar se emulador está conectado
adb devices

# Se não mostrar emulator-5556, reinicie a conexão
adb kill-server
adb start-server
```

### Problema: Muitos logs irrelevantes
**Solução:** Use `watch-bot-only.sh` para ver apenas mensagens do bot.

---

## 💡 Dica Pro

Para monitorar em **duas janelas** simultaneamente:

**Terminal 1:** Logcat (técnico)
```bash
./watch-logcat.sh
```

**Terminal 2:** Arquivo de log (oficial)
```bash
./watch-log-file.sh
```

Assim você vê logs técnicos E os logs salvos em arquivo! 🎯
