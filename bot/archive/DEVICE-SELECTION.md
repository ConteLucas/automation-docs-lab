# Device Selection - Scripts Atualizados

**Data**: 2026-02-15  
**Contexto**: Suporte para múltiplos devices/emuladores

---

## 🎯 Problema Resolvido

Os scripts estavam com device **hardcoded** (`emulator-5556`), mas o usuário estava usando `emulator-5554`. Isso causava falha nos clicks porque o Accessibility Service estava habilitado no device errado.

---

## 🔧 Solução Implementada

### 1. **Script Auxiliar: `select-device.sh`**

Criado um script centralizado para seleção de device que:

- ✅ Detecta automaticamente se há **apenas 1 device** conectado (usa ele)
- ✅ Se houver **múltiplos devices**, pergunta qual usar
- ✅ Permite passar o device como **argumento** (ex: `./run.sh emulator-5554`)
- ✅ Suporta variável de ambiente `DEVICE` (ex: `DEVICE=emulator-5554 ./run.sh`)
- ✅ Default: `emulator-5554` se nenhum for especificado

**Uso:**
```bash
# Automático (se só tiver 1 device)
DEVICE=$(./select-device.sh)

# Manual
DEVICE=$(./select-device.sh emulator-5554)
```

### 2. **Scripts Atualizados**

Todos os scripts agora usam `select-device.sh` internamente:

#### Build e Instalação:
- ✅ `run.sh` - Build e install
- ✅ `clean-install.sh` - Clean install

**Uso:**
```bash
# Pergunta qual device (se houver mais de 1)
./run.sh

# Especifica o device
./run.sh emulator-5554
```

#### Monitoramento:
- ✅ `watch-logcat.sh` - Logs detalhados
- ✅ `watch-bot-only.sh` - Logs filtrados
- ✅ `diagnose-accessibility.sh` - Diagnóstico

**Uso:**
```bash
# Pergunta qual device (se houver mais de 1)
./watch-logcat.sh

# Especifica o device
./watch-logcat.sh emulator-5554
```

---

## 📋 Como Usar

### Cenário 1: Apenas 1 Device Conectado
```bash
./run.sh
# Detecta automaticamente e usa o device disponível
```

### Cenário 2: Múltiplos Devices
```bash
./run.sh
# Output:
# Available devices:
#      1  emulator-5554    device
#      2  emulator-5556    device
# Select device number (or press Enter for emulator-5554): 1
# Using device: emulator-5554
```

### Cenário 3: Especificar Device Direto
```bash
./run.sh emulator-5554
# Using device: emulator-5554
```

### Cenário 4: Usar Variável de Ambiente
```bash
export DEVICE=emulator-5554
./run.sh
./watch-logcat.sh
./diagnose-accessibility.sh
# Todos vão usar emulator-5554
```

---

## 🎓 Benefícios

1. **Flexibilidade**: Suporta múltiplos devices/emuladores
2. **Automação**: Detecta automaticamente se só tiver 1 device
3. **Consistência**: Todos os scripts usam a mesma lógica
4. **Facilidade**: Pode especificar device como argumento ou variável de ambiente
5. **Segurança**: Validação de device antes de executar comandos

---

## 🔍 Scripts Não Atualizados

Estes scripts **não** foram atualizados pois são menos críticos:

- `build-and-run.sh` (use `run.sh` no lugar)
- `diagnostic.sh` (use `diagnose-accessibility.sh` no lugar)
- `restart-accessibility.sh` (raramente usado)
- `watch-log-file.sh` (menos usado)
- `watch-logs.sh` (menos usado)

Se precisar atualizar algum deles, basta adicionar no início:

```bash
SCRIPT_DIR="$(dirname "$0")"
DEVICE=$(bash "$SCRIPT_DIR/select-device.sh" "$1")
if [ $? -ne 0 ]; then
    exit 1
fi
```

E trocar `emulator-5556` por `"$DEVICE"`.

---

## ✅ Teste Realizado

O usuário confirmou que o click funciona corretamente no `emulator-5554`:

```
[INFO] Click executed via Accessibility at (1238, 1125)
```

O problema era que os scripts estavam usando `emulator-5556`, onde o Accessibility Service não estava configurado.

---

**Status**: ✅ Scripts principais atualizados e testados  
**Próximo passo**: Continuar implementação do bot com o device correto
