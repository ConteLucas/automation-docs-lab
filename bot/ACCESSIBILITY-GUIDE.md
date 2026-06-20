# 🔧 GUIA DEFINITIVO - Habilitar Accessibility Service

## ⚠️ IMPORTANTE: Após TODA Reinstalação do App

Sempre que você reinstalar o app (via `adb install -r`), você **DEVE** fazer isso:

### 📋 Passo a Passo (2 minutos):

1. **Abra Settings** no emulador
2. **Accessibility**
3. Encontre **"Bot DDT"**
4. Se estiver **ON**: Toggle **OFF** → Toggle **ON**
5. Se estiver **OFF**: Toggle **ON**
6. **Confirme** quando pedir permissão
7. **Volte ao app Bot DDT**

---

## ✅ Como Saber se Funcionou:

Execute o monitoramento:
```bash
./watch-logcat.sh
```

Abra o app Bot DDT. Você deve ver:
```
✅ BotAccessibilityService connected
🔗 ScreenClicker notified of service connection
```

Se **NÃO aparecer**, repita os passos acima.

---

## 🎯 Depois de Habilitar:

1. Clique em START no app
2. Veja os logs:

```
✅ Accessibility service available
📍 Created gesture path at (1238, 1125)
🎯 Dispatching gesture...
✅ Click executed successfully at (1238, 1125)
```

---

## 🚀 Melhorias Implementadas:

1. ✅ **Auto-limpeza de logs** - Mantém apenas os últimos 3 arquivos
2. ✅ **Logs mais detalhados** - Mostra onCreate, onDestroy, onUnbind
3. ✅ **Configuração melhorada** - Flags adicionais para estabilidade
4. ✅ **Logs limpos no dispositivo** - Apenas 1 arquivo mantido

---

## 📝 Lembrete:

**A cada vez que você executar:**
```bash
./gradlew assembleDebug && adb install -r ...
```

**Você PRECISA desabilitar/habilitar o serviço manualmente.**

Isso é uma limitação de segurança do Android. Não há como automatizar.
