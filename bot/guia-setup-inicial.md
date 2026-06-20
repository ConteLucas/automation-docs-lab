# 🔧 Setup & Troubleshooting

## 📦 Instalação

### **Opção 1: Android Studio (Recomendado)**

1. Abrir Android Studio
2. `File → Open` → Selecionar pasta `automation-bot-ddt`
3. Aguardar sincronização do Gradle
4. `Build → Rebuild Project`
5. `▶️ Run 'app'`

### **Opção 2: Linha de Comando**

```bash
cd automation-bot-ddt

# Compilar
./gradlew assembleDebug

# Instalar
adb install app/build/outputs/apk/debug/app-debug.apk

# Executar
adb shell am start -n com.automation.bot/.ui.MainActivity
```

---

## ⚙️ Configurações

### **Gradle**
- Versão: **8.6**
- Android Gradle Plugin: **8.4.0**
- Kotlin: **1.9.20**

### **Android**
- compileSdk: **34**
- minSdk: **26**
- targetSdk: **34**

---

## 🐛 Troubleshooting

### **Erro: "Minimum supported Gradle version is 8.6"**

**Solução:**
```bash
# No Android Studio:
File → Settings → Build Tools → Gradle
Selecionar: 'gradle-wrapper.properties' file
Apply → OK

# Depois:
File → Invalidate Caches... → Invalidate and Restart
```

---

### **Erro: "Cannot use connection to Gradle distribution"**

**Causa:** Daemon do Gradle travado

**Solução:**
```bash
# Fechar Android Studio completamente
# Aguardar 5 segundos
# Reabrir Android Studio

# Ou via terminal:
cd automation-bot-ddt
./gradlew --stop
rm -rf .gradle
./gradlew clean
```

---

### **Erro: Theme.AppCompat (crash ao abrir app)**

**Causa:** Tema não configurado corretamente

**Solução:** Já está corrigido no `themes.xml`:
```xml
<style name="Theme.BotDDT" parent="Theme.AppCompat.Light.NoActionBar">
```

---

### **Erro: "DDTank BR não está instalado"**

**Solução:**
```bash
# Verificar se está instalado
adb shell pm list packages | grep ddtank

# Se não aparecer nada, instalar o DDTank primeiro
```

---

### **Build muito lento**

**Solução 1: Aumentar memória do Gradle**
```properties
# gradle.properties
org.gradle.jvmargs=-Xmx4096m -Dfile.encoding=UTF-8
```

**Solução 2: Limpar cache**
```bash
./gradlew clean
rm -rf .gradle
rm -rf app/build
```

---

### **Android Studio não sincroniza**

**Solução:**
```
1. File → Invalidate Caches...
2. Marcar TODAS as opções
3. "Invalidate and Restart"
4. Aguardar reiniciar
5. File → Sync Project with Gradle Files
```

---

### **ADB não encontra device**

**Solução:**
```bash
# Listar devices
adb devices

# Se vazio, reiniciar ADB
adb kill-server
adb start-server
adb devices

# Ou reiniciar emulador:
# Android Studio → Tools → Device Manager → Stop → Start
```

---

### **Erro de compilação do Kotlin**

**Solução:**
```bash
# Limpar build
./gradlew clean

# Invalidar caches
rm -rf .gradle
rm -rf .idea

# Reabrir projeto no Android Studio
```

---

## 🔍 Logs e Debug

### **Ver logs do Bot em tempo real:**
```bash
adb logcat | grep BotApp
```

### **Ver todos os logs:**
```bash
adb logcat | grep -E "BotApp|DDTank|MainActivity"
```

### **Limpar logs:**
```bash
adb logcat -c
```

### **Salvar logs em arquivo:**
```bash
adb logcat > logs.txt
```

---

## 📱 Emulador Recomendado

- **Device:** Pixel 5
- **Android Version:** 13 (API 33) ou superior
- **RAM:** 2GB+
- **Graphics:** Hardware - GLES 2.0

---

## ✅ Checklist de Verificação

Antes de reportar problemas, verificar:

- [ ] Gradle 8.6 instalado
- [ ] Android SDK 34 instalado
- [ ] JDK 17 configurado
- [ ] Device/Emulador conectado (`adb devices`)
- [ ] DDTank BR instalado no device
- [ ] Caches do Android Studio invalidados
- [ ] Projeto sincronizado com Gradle

---

## 🆘 Suporte

Se nenhuma solução acima funcionar:

1. **Coletar logs:**
   ```bash
   adb logcat > error_logs.txt
   ```

2. **Informações do sistema:**
   ```bash
   ./gradlew --version
   adb --version
   java -version
   ```

3. **Descrever:**
   - O que estava fazendo
   - Erro exato
   - Steps para reproduzir
