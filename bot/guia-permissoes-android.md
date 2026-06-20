# 🔐 Android Permissions - Explained

**Data**: 2026-03-01  
**Tópico**: Por que algumas permissões aparecem em Settings e outras não

---

## 📱 Permissões Visíveis em Settings → Apps → Permissions

### Como Funciona:

Quando você vai em **Settings → Apps → Bot DDT → Permissions**, o Android mostra apenas:

1. **Dangerous Permissions** (Runtime permissions)
2. **Special App Access** (Special permissions)

---

## 🔍 Tipos de Permissões no Android

### 1️⃣ Normal Permissions (Aprovadas automaticamente)

❌ **NÃO aparecem** em Settings → Permissions

**Exemplos no Bot DDT**:
- `INTERNET` - Acesso à internet
- `ACCESS_NETWORK_STATE` - Ver estado da rede
- `WAKE_LOCK` - Manter CPU ativa
- `FOREGROUND_SERVICE` - Rodar service em foreground

**Por quê não aparecem?**
- O Android aprova automaticamente no install
- Usuário não pode revogar
- São consideradas "baixo risco"

---

### 2️⃣ Dangerous Permissions (Runtime - Usuário aprova)

✅ **APARECEM** em Settings → Permissions

**Exemplos que DEVERIAM aparecer no Bot DDT**:
- `READ_EXTERNAL_STORAGE` - Ler arquivos (para logs)
- `WRITE_EXTERNAL_STORAGE` - Escrever arquivos (para logs)
- `READ_MEDIA_IMAGES` - Ler imagens (Android 13+)
- `READ_MEDIA_VIDEO` - Ler vídeos (Android 13+)

**Por quê aparecem?**
- Usuário PODE revogar
- App precisa solicitar em runtime
- Consideradas "alto risco" para privacidade

**Problema atual**: O Bot DDT **não está solicitando** essas permissões em runtime, então elas não aparecem!

---

### 3️⃣ Special Permissions (Requerem UI do sistema)

✅ **APARECEM** em Settings → Special app access

**Exemplos no Bot DDT**:

#### A. Display over other apps (Overlay)
- Permissão: `SYSTEM_ALERT_WINDOW`
- Aparece em: **Settings → Special app access → Display over other apps**
- **Status atual**: ✅ Implementado (app solicita via Settings)

#### B. Accessibility (Accessibility Service)
- Permissão: `BIND_ACCESSIBILITY_SERVICE`
- Aparece em: **Settings → Accessibility → Bot DDT**
- **Status atual**: ✅ Implementado (usuário ativa manualmente)

#### C. Screen capture (MediaProjection)
- **NÃO requer** permissão no Manifest
- Aparece em: **Settings → Special app access → Modify system settings** (às vezes)
- **Status atual**: ✅ Implementado (popup runtime)
- **Observação**: Esta permissão **nem sempre** aparece em Settings porque é uma "session permission" (válida enquanto app está rodando)

---

## ⚠️ Por Que Bot DDT Tem Poucas Permissões Visíveis?

### Situação Atual:

Quando você abre **Settings → Apps → Bot DDT → Permissions**, provavelmente vê algo assim:

```
App permissions:
  (empty or very few)
```

### Motivos:

1. **A maioria das permissões são "Normal"**
   - `INTERNET`, `WAKE_LOCK`, etc não aparecem

2. **Storage permissions não estão sendo solicitadas em runtime**
   - Apenas declaradas no Manifest
   - App nunca chamou `requestPermissions()`

3. **Special permissions aparecem em outro lugar**
   - Overlay → Special app access
   - Accessibility → Accessibility settings
   - MediaProjection → Não aparece (session permission)

---

## ✅ Como Fazer Aparecer Mais Permissões

### Opção 1: Solicitar Storage Permissions (Recomendado)

Adicionar código para solicitar permissões de armazenamento:

```kotlin
// MainActivity.kt
private fun requestStoragePermissions() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        // Android 13+
        requestPermissions(
            arrayOf(
                Manifest.permission.READ_MEDIA_IMAGES,
                Manifest.permission.READ_MEDIA_VIDEO
            ),
            REQUEST_STORAGE_PERMISSION
        )
    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        // Android 6-12
        requestPermissions(
            arrayOf(
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            ),
            REQUEST_STORAGE_PERMISSION
        )
    }
}
```

**Resultado**: Vai aparecer em **Settings → Apps → Bot DDT → Permissions → Files and media**

---

### Opção 2: Adicionar Mais Dangerous Permissions

Se quisermos que apareçam mais permissões, podemos adicionar:

```xml
<!-- AndroidManifest.xml -->

<!-- Camera (se precisar no futuro) -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Location (se precisar no futuro) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Microphone (se precisar no futuro) -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

**Mas**: Só devemos adicionar se **realmente** precisarmos!

---

## 🎯 Recomendação para Bot DDT

### Permissões que DEVEM estar visíveis:

1. **✅ Display over other apps** (Overlay)
   - Já implementado
   - Aparece em: Special app access

2. **✅ Accessibility** (Clicks)
   - Já implementado
   - Aparece em: Accessibility settings

3. **🆕 Files and media** (Storage)
   - Atualmente não solicita
   - **Deveria** solicitar para salvar logs
   - Vai aparecer em: Permissions → Files and media

4. **❌ Screen capture** (MediaProjection)
   - Já implementado com popup
   - **Não aparece** em Permissions (é session-based)
   - É normal que não apareça!

---

## 📊 Comparação com Outros Apps

### App de Screen Recording (ex: AZ Screen Recorder):

**Permissions visíveis**:
- ✅ Storage (Files and media)
- ✅ Microphone (se gravar áudio)
- ✅ Camera (para overlay de câmera)

**Special access**:
- ✅ Display over other apps
- ✅ Modify system settings
- ✅ Screen capture (às vezes não aparece)

---

### Bot DDT (Situação Atual):

**Permissions visíveis**:
- ❌ (vazio ou quase vazio)

**Special access**:
- ✅ Display over other apps
- ✅ Accessibility

**Por quê diferente?**
- Bot DDT não solicita Storage em runtime
- Bot DDT não usa Camera, Microphone, Location

---

## 🔧 Como Corrigir?

Vou implementar a solicitação de **Storage permissions** em runtime para que apareça em Settings → Permissions!

Isso vai fazer o bot parecer mais "profissional" e dar ao usuário controle sobre o acesso a arquivos.

---

## 📝 Resumo

### Permissões que NÃO aparecem (Normal):
- INTERNET
- WAKE_LOCK
- FOREGROUND_SERVICE
- ACCESS_NETWORK_STATE

### Permissões que APARECEM mas em Special Access:
- SYSTEM_ALERT_WINDOW (Overlay)
- BIND_ACCESSIBILITY_SERVICE (Accessibility)
- MediaProjection (Não sempre visível)

### Permissões que DEVERIAM aparecer mas não aparecem:
- READ_EXTERNAL_STORAGE
- WRITE_EXTERNAL_STORAGE
- READ_MEDIA_IMAGES

**Motivo**: Nunca chamamos `requestPermissions()` em runtime!

---

**Quer que eu implemente a solicitação de Storage permissions?** 

Isso vai fazer aparecer "Files and media" em Settings → Permissions! 📂
