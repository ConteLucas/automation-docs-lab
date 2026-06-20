# DDT — Login híbrido + servidor variável (mitm rewrite)

Guia do fluxo validado em POC: **login por Accessibility no bot**, **entrada no servidor (S10/S11/S12…) sem scroll na lista Cocos**, via **mitmproxy no Mac** que reescreve `serverid` no tráfego **do jogo**.

**Última atualização:** 2026-06-06

---

## Visão geral

```text
┌─────────────────────────────────────────────────────────────────┐
│ Mac                                                             │
│  task.serverValue → bridge set-server → mitm rewrite → JSONL   │
├─────────────────────────────────────────────────────────────────┤
│ Emulador Android (proxy 10.0.2.2:8888, cert system 1×)          │
│  DDT (jogo)          — HTTPS passa pelo mitm                    │
│  automation-bot-ddt  — login A11y + tap «Entrar»                │
└─────────────────────────────────────────────────────────────────┘
         ↑
    Core API (task.serverValue = "S12")
```


| Camada      | O quê                                           | Onde vive                  |
| ----------- | ----------------------------------------------- | -------------------------- |
| **BUILD**   | Login A11y + tap Entrar + `serverValue` da task | APK `automation-bot-ddt`   |
| **SETUP**   | Emulador gravável + cert mitm em `/system`      | 1× por AVD (scriptado)     |
| **RUNTIME** | Bridge `set-server` (bot) + mitm rewrite        | Mac (`bot-stack` + bridge) |


---

## Porque funciona (sem clicar em S12 na lista)

1. O jogador faz login e chega à **lista de servidores** (a UI pode mostrar **S10**, o último jogado).
2. Ao tocar **«Entrar no jogo»**, o DDT envia HTTP com o id do servidor **visível** (ex.: `serverid=523` = S10).
3. O **mitm** intercepta o pedido **antes** de chegar a `wan.com` e troca para o servidor da task (ex.: `525` = S12).
4. O **servidor** responde como se tivesses escolhido S12; o **cliente** recebe as respostas e carrega a cidade.

> O script `enter-server.py` no Mac **não** substitui isto: corre fora do processo do jogo. O rewrite no mitm funciona porque o tráfego é **do emulador → proxy → internet**.

---

## Pré-requisitos


| Ferramenta | Instalação                               |
| ---------- | ---------------------------------------- |
| mitmproxy  | `brew install mitmproxy`                 |
| Python 3   | sistema / pyenv                          |
| adb        | Android SDK platform-tools               |
| Emulador   | AVD com `-writable-system` (cert system) |
| OpenSSL    | para hash do cert (macOS já tem)         |


**Pacote DDT:** `com.road7.ddtankbr.gp`

---

## 1. SETUP do emulador (uma vez por AVD)

**Runbook mitm + cert (copiar/colar):** [runbook-mitm-emulador.md](runbook-mitm-emulador.md)

**Passo a passo desmembrado (recomendado):** [scripts/ddt/emulator-setup/README.md](../../../scripts/ddt/emulator-setup/README.md)

Fases **A → I**: ferramentas → AVD gravável → cert → reboot → `set-server` → `prepare` → `verify` → testar DDT.

Resumo das fases principais:


| Fase | Comando                                               |
| ---- | ----------------------------------------------------- |
| A    | `./scripts/ddt/emulator-setup/check.sh`               |
| B–C  | `adb emu kill` → `emulator -avd … -writable-system …` |
| D–E  | `install-cert` → `adb reboot`                         |
| F–H  | `bot-stack` (ou `prepare`) → `verify` — servidor via task no bot |
| I    | Login DDT → tap Entrar → `grep rewrite` no log        |


Atalho automático (opcional): `./scripts/ddt/setup-emulator.sh --server S12`

### 1.1 O que o cert faz

- O DDT usa HTTPS e **não confia** em CA de utilizador normal.
- O cert do mitm tem de estar em `**/system/etc/security/cacerts/`** (emulador root).
- Isto **não** vai dentro do APK do bot — é configuração do **ambiente** (scriptável com `install-cert`).

### 1.2 Mapa de servidores (opcional, recomendado)

Depois de um login até `serverlist`:

```bash
./scripts/ddt/capture-traffic.sh refresh-server-map
```

Grava `.local/ddt-traffic/server-map.json` (ex.: S12 → id `525`, shard `s10`).

---

## 2. RUNTIME — por task / por sessão

### 2.1 Servidor da task (vem do Core, não do terminal)

Com o **bot** activo:

```text
claim-next → task.serverValue (ex. S3, S12 — o que a conta/task pede)
     ↓
TaskCycleRunner → GET http://10.0.2.2:8799/set-server/S3
     ↓
target-server no Mac → mitm rewrite no jogo
```

Confirma no Mac após claim: `./scripts/ddt/capture-traffic.sh target-server`

**Só teste manual** (sem bot):

```bash
./scripts/ddt/capture-traffic.sh set-server S12
```

Servidores no mesmo shard `s10` (exemplos):


| Nome | serverid | shard |
| ---- | -------- | ----- |
| S10  | 523      | s10   |
| S11  | 524      | s10   |
| S12  | 525      | s10   |


Para outro servidor: `set-server S18` (shard `s18` — o addon também redireciona o host se necessário).

### 2.2 Arrancar mitm com rewrite

Sempre que mudas `set-server`, **reinicia** o mitm:

```bash
./scripts/ddt/capture-traffic.sh stop
./scripts/ddt/capture-traffic.sh prepare
./scripts/ddt/capture-traffic.sh verify
```

`prepare` = `mitmdump` + proxy no emulador + addons:

- `scripts/ddt/mitm-addon-ddt.py` — log JSONL
- `scripts/ddt/mitm-addon-rewrite-server.py` — rewrite `statecheck` / `queryplayer`

### 2.3 Fluxo no emulador (manual ou bot)

1. Abrir DDT
2. **Login** (user + password) — futuro: `FlowLoginUseCase`
3. Parar na lista de servidores (**não** é obrigatório selecionar S12)
4. Tap **«Entrar no jogo»** — futuro: template Vision

### 2.4 Confirmar rewrite

```bash
tail -20 .local/ddt-traffic/mitmdump.log | grep rewrite
```

Exemplo esperado (UI em S10, task S12):

```text
[rewrite] statecheck serverid 523 → 525 (S12)
[rewrite] queryplayer areaid 523 → 525 (S12)
```

### 2.5 Comandos úteis de diagnóstico

```bash
./scripts/ddt/capture-traffic.sh status
./scripts/ddt/capture-traffic.sh tokenkey
./scripts/ddt/capture-traffic.sh enter-server --from-capture --list-servers
./scripts/ddt/capture-traffic.sh logs-ddt
./scripts/ddt/capture-traffic.sh analyze --timeline
```

---

## 3. BUILD — integração no bot (roadmap)

### 3.1 O que já existe no APK


| Peça             | Ficheiro / nota                                                       |
| ---------------- | --------------------------------------------------------------------- |
| Login A11y       | `FlowLoginUseCase.loginAndPassword`, `buttonLoginTap`                 |
| Tap Entrar       | `validServer()` comentado — reativar com template `button_enter_game` |
| Servidor da task | `TaskWorkerPlanTaskDto.serverValue` (Core API)                        |


### 3.2 O que o bot **não** faz (ainda)

- Não corre mitm nem rewrite (outro processo / Mac).
- Não instala cert system.

### 3.3 Encadeamento alvo

```text
1. Orquestrador (Mac/CI) lê task.serverValue do Core
2. ./scripts/ddt/capture-traffic.sh set-server "${serverValue}"
3. ./scripts/ddt/capture-traffic.sh stop && prepare
4. Bot: FlowLoginUseCase (credenciais da task)
5. Bot: DetectAndClick «Entrar no jogo»
6. Combate / resto do flow (Vision)
```

**Ligação Core → Mac:** script, API HTTP local, ou variável de ambiente no runner de CI — a implementar.

### 3.4 Credenciais da task

Do worker plan:

- `gameAccountLogin`
- `gameAccountPassword`
- `serverValue` (ex. `"S12"`)

---

## 4. Arquitetura de ficheiros

```text
scripts/ddt/
  capture-traffic.sh          # orquestração: prepare, set-server, verify, …
  mitm-addon-ddt.py           # captura JSONL
  mitm-addon-rewrite-server.py # rewrite serverid/areaid (+ host cross-shard)
  enter-server.py             # POC HTTP direto (debug; não usar em produção)

.local/ddt-traffic/
  target-server               # ex.: S12 (uma linha)
  server-map.json             # S12 → { id, shard }
  captures/latest-summary.jsonl
  mitmdump.log

automation-bot-ddt/
  FlowLoginUseCase.kt         # login + (futuro) tap Entrar
```

---

## 5. Troubleshooting


| Sintoma                               | Causa provável                               | Ação                                            |
| ------------------------------------- | -------------------------------------------- | ----------------------------------------------- |
| Entra sempre no último servidor da UI | Rewrite inativo                              | `set-server` + `stop && prepare`                |
| `grep rewrite` vazio                  | Addon não carregado ou `target-server` vazio | `target-server`, ver `mitmdump.log` no arranque |
| TLS / cert unknown                    | Cert não em system                           | `emulator-writable` + `install-cert` + reboot   |
| Só httpbin no summary                 | Jogaste sem mitm ou cert                     | `verify` → jogar DDT → `summary`                |
| `tokenkey` vazio                      | Login não chegou a `serverlist`              | Repetir login com mitm a correr                 |
| Combate não automatiza                | Socket TCP não passa no HTTP proxy           | Vision / outro protocolo (fora deste doc)       |


---

## 6. Limitações conhecidas

1. **Mitm no Mac** — emulador tem de usar proxy `10.0.2.2:8888`; não escala a N devices sem orquestração.
2. **Cert system** — emulador root/writable; telemóvel real é muito mais difícil (pinning).
3. **Rewrite só HTTP** — combate usa **TCP** (`login` devolve `ip:port` + `key`); mitm não vê esse socket.
4. `**enter-server.py` no Mac** — útil para testar APIs; **não** move o cliente do jogo sozinho.

### Evolução futura (sem mitm no Mac)

- Frida / hook OkHttp no processo `com.road7.ddtankbr.gp`
- Proxy local no device (módulo companion) — ainda exige cert + proxy

---

## 7. Checklist rápido (copiar/colar)

**Setup 1× (novo AVD):** ver fases A–I em [emulator-setup/README.md](../../../scripts/ddt/emulator-setup/README.md)

**Cada sessão (bot):**

```bash
./scripts/ddt/capture-traffic.sh bot-stack
# → Start no bot → claim-next define servidor via bridge
./scripts/ddt/capture-traffic.sh target-server   # confirma após claim
tail -5 .local/ddt-traffic/mitmdump.log | grep rewrite
```

**Mudar servidor:** nova task no Core com outro `serverValue` — o bot chama `/set-server/…` no claim seguinte (sem terminal).

**POC manual (sem bot):**

```bash
./scripts/ddt/capture-traffic.sh set-server S12
./scripts/ddt/capture-traffic.sh prepare && ./scripts/ddt/capture-traffic.sh verify
```

---

## 8. Referências

- Captura e análise de tráfego: `scripts/ddt/capture-traffic.sh help`
- Worker plan / `serverValue`: `TaskWorkerPlanResponseDto.kt`
- Templates pós-login: `automation-bot-ddt/app/src/main/assets/templates/ddt/post_login/`
- Orquestrador Core: [guia-orquestrador-task-core.md](guia-orquestrador-task-core.md)

