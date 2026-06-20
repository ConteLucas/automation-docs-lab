# DDT — Runbook mitm + emulador (cert system)

Guia **cirúrgico** para pôr o mitm no Mac a interceptar o **jogo DDT** no emulador, com rewrite de servidor (S10→S12) e **bot a falar directo** com Core/Vision.

**Última validação:** 2026-06-09 (AVD `device-default_12`, API 30)

Guia de arquitetura: [guia-login-servidor-mitm.md](guia-login-servidor-mitm.md)

---

## Arquitetura em 30 segundos

```text
Mac :8888  mitmdump (+ rewrite + captura JSONL)
         ▲
         │  proxy global 10.0.2.2:8888
Emulador │
         ├── com.road7.ddtankbr.gp (jogo)  → PASSA pelo mitm
         └── automation-bot-ddt (bot)      → Core :8081 / Vision :8082 DIRECTO
                                              (OkHttp Proxy.NO_PROXY)
```

| Componente | Precisa mitm? |
|------------|----------------|
| Jogo DDT | **Sim** — proxy global + cert em `/system` |
| Bot → Core/Vision | **Não** — `NO_PROXY` no `CoreApiService` / `VisionApiService` |
| Mitm no Mac | **Sim** — `capture-traffic.sh prepare` |

---

## Pré-requisitos

```bash
cd ~/Developer/learning/automation-learn
./scripts/ddt/emulator-setup/check.sh   # mitmdump, adb, emulator, openssl
brew install mitmproxy                # se faltar
```

Substitui `device-default_12` pelo teu AVD:

```bash
emulator -list-avds
```

---

## Parte 1 — Setup **1× por AVD** (cert system)

> Sem isto, `install-cert` dá `remount failed` e o DDT **não loga** com mitm activo.

### 1.1 Fechar emulador normal

```bash
adb emu kill
adb devices   # não deve listar device online
```

**Não** abras o emulador pelo ícone do Android Studio — tens de usar `-writable-system` na linha de comandos.

### 1.2 Arrancar com `/system` gravável

```bash
emulator -avd device-default_12 -writable-system -no-snapshot-load &
```

### 1.3 Esperar boot

```bash
adb wait-for-device
adb shell getprop sys.boot_completed   # repetir até devolver 1
sleep 15
```

### 1.4 Root + remount

```bash
adb root
adb remount
```

**Esperado:**

```text
Using overlayfs for /system
...
remount succeeded
```

Se pedir reboot após remount, faz:

```bash
adb reboot
adb wait-for-device && sleep 15
adb root && adb remount
```

### 1.5 Instalar cert mitm no system store

```bash
cd ~/Developer/learning/automation-learn
./scripts/ddt/capture-traffic.sh install-cert
```

**Esperado:**

```text
[ddt-traffic] Cert system instalado (c8750f0d.0) — corre: adb reboot && ./scripts/ddt/capture-traffic.sh prepare
```

### 1.6 Confirmar ficheiro (obrigatório)

```bash
adb shell ls -la /system/etc/security/cacerts/c8750f0d.0
```

**Esperado:** `-rw-r--r-- ... c8750f0d.0` — **não** `MISSING`.

### 1.7 Reboot (Android carrega CAs do system)

```bash
adb reboot
adb wait-for-device && sleep 15
```

Setup do AVD **concluído**. Não precisas repetir 1.1–1.7 enquanto mantiveres o mesmo AVD com cert instalado.

---

## Parte 2 — **Cada sessão** (mitm + rewrite)

### 2.1 Servidor da task

**Com bot (produção):** após `claim-next`, o app chama `GET /set-server/{task.serverValue}` no bridge — **não** precisas de `set-server` manual.

**Só POC manual** (sem Core/bot):

```bash
./scripts/ddt/capture-traffic.sh set-server S12
./scripts/ddt/capture-traffic.sh target-server
```

### 2.2 Subir mitm no Mac + proxy no emulador

```bash
./scripts/ddt/capture-traffic.sh stop    # limpa sessão anterior (opcional mas recomendado)
./scripts/ddt/capture-traffic.sh prepare
```

O `prepare` faz: `mitmdump :8888` + addons (captura + rewrite) + `http_proxy 10.0.2.2:8888` + push cert para Downloads.

**Esperado:**

```text
[ddt-traffic] mitmdump PID …
[ddt-traffic] Rewrite servidor (tráfego do jogo): S12
[ddt-traffic] Proxy global: 10.0.2.2:8888
```

### 2.3 Confirmar estado

```bash
./scripts/ddt/capture-traffic.sh status
./scripts/ddt/capture-traffic.sh verify          # httpbin — necessário mas não suficiente
./scripts/ddt/capture-traffic.sh logs-ddt        # wan.com SEM handshake failed
```

`verify` ✅ **não garante** DDT — confia em `logs-ddt` sem:

```text
Client TLS handshake failed ... wan.com ... certificate unknown
```

### 2.4 Jogar / bot

1. Abre **DDT** → login → lista servidores → **Entrar no jogo**
2. Confirma rewrite:

```bash
tail -f .local/ddt-traffic/mitmdump.log | grep --line-buffered rewrite
```

Exemplo:

```text
[rewrite] statecheck serverid 523 → 525 (S12)
[rewrite] queryplayer areaid 523 → 525 (S12)
```

3. Corre o **bot** (Core/Vision no Mac em `:8081` / `:8082`)

Ver requests ao vivo:

```bash
./scripts/ddt/capture-traffic.sh follow
```

Captura após jogar:

```bash
./scripts/ddt/capture-traffic.sh summary
./scripts/ddt/capture-traffic.sh analyze --timeline
```

---

## Parte 2b — Antes de **Start** no app bot

O mitm corre no **Mac** — o app Android **não** pode arrancar `mitmdump`. O emulador só precisa de proxy + cert; o Mac precisa de mitm + bridge.

**Um comando no Mac (antes de abrir o bot no emulador):**

```bash
cd ~/Developer/learning/automation-learn
./scripts/ddt/capture-traffic.sh bot-stack
```

Isso faz: `ensure-mitm` (mitmdump + `http_proxy 10.0.2.2:8888`) + `serve` (bridge `:8799`).

### Cenários a ter em mente

| Cenário | O que precisas |
|---------|----------------|
| **Dia normal** | Mac: `bot-stack` → emulador já booted → **Start** no bot |
| **Só abriste o emulador** | `bot-stack` (mitm pode ter parado após `stop` ou fechar terminal) |
| **`adb reboot`** | Cert system mantém; `recover` ou `bot-stack` (reaplica proxy) |
| **Mac reboot** | `bot-stack` de novo (mitm e bridge morreram) |
| **Correste `stop`** | `bot-stack` (mitm parado + proxy off) |
| **Primeira vez no AVD** | Parte 1 (cert system) **antes** de qualquer sessão |
| **DDT já aberto sem mitm** | Tráfego perdido — melhor `bot-stack` **antes** do Start no bot |
| **Bridge OK mas sem mitm** | Bridge OK; `GET_ROLE_GRADE` / `role-level` falham (JSONL vazio) |

### Servidor da task (não é manual)

O servidor **não** vem de `set-server S12` no terminal. Fluxo com bot:

```text
Core claim-next → task.serverValue (ex. S3, S12, …)
       ↓
Bot → GET http://10.0.2.2:8799/set-server/S3
       ↓
Mac grava .local/ddt-traffic/target-server
       ↓
Mitm rewrite no tráfego do jogo
```

`./scripts/ddt/capture-traffic.sh set-server S12` é só para **teste manual** sem bot.

### Ordem recomendada

```text
1. Mac:     bot-stack
2. AVD:     boot (cert system já instalado)
3. App bot: Start → health OK → claim-next → set-server automático (serverValue da task)
4. DDT:     abre — tráfego passa pelo mitm com rewrite do servidor certo
```

O bot verifica `GET http://10.0.2.2:8799/health` no Start (warn se falhar).

**Não misturar:** `stop` no Mac enquanto o jogo usa proxy → DDT sem rede. O bot Core/Vision segue directo (`NO_PROXY`).

---

## Parte 3 — Após `adb reboot` (mitm no Mac continua)

```bash
./scripts/ddt/capture-traffic.sh recover
./scripts/ddt/capture-traffic.sh verify
./scripts/ddt/capture-traffic.sh logs-ddt
```

---

## Parar (jogar sem mitm)

```bash
./scripts/ddt/capture-traffic.sh stop
```

Remove proxy do emulador e mata `mitmdump` no Mac.

---

## Troubleshooting

| Sintoma | Causa | Acção |
|---------|--------|--------|
| `remount failed` | Emulador sem `-writable-system` | Parte 1.1–1.2 de novo |
| `verify` ✅ mas DDT não loga | Cert só em Downloads, não em `/system` | Parte 1.5–1.7 |
| `handshake failed ... wan.com` | Cert não confiável pelo jogo | `ls c8750f0d.0` + reboot |
| Bot 502 em `:8082` com mitm | OkHttp a usar proxy global | Já corrigido: `Proxy.NO_PROXY` no bot |
| `grep rewrite` vazio | Task sem `serverValue` ou mitm parado | claim-next + `bot-stack`; ver `target-server` |

---

## Referência rápida (colar)

**Setup 1× (AVD novo):**

```bash
adb emu kill
emulator -avd device-default_12 -writable-system -no-snapshot-load &
adb wait-for-device && sleep 15
adb root && adb remount
cd ~/Developer/learning/automation-learn
./scripts/ddt/capture-traffic.sh install-cert
adb shell ls -la /system/etc/security/cacerts/c8750f0d.0
adb reboot && adb wait-for-device && sleep 15
```

**Sessão (bot):**

```bash
cd ~/Developer/learning/automation-learn
./scripts/ddt/capture-traffic.sh bot-stack
# → Start no app bot (servidor vem da task no claim-next, não set-server manual)
```

**Parar:**

```bash
./scripts/ddt/capture-traffic.sh stop
```

---

## Ficheiros úteis

| Ficheiro | Conteúdo |
|----------|----------|
| `.local/ddt-traffic/mitmdump.log` | TLS, rewrite, `[DDT]` |
| `.local/ddt-traffic/captures/latest-summary.jsonl` | Trail JSONL |
| `.local/ddt-traffic/target-server` | Servidor rewrite (ex. `S12`) |
| `scripts/ddt/capture-traffic.sh help` | Todos os comandos |
