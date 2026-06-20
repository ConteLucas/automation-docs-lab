# Device Lab — setup salvo e multi-plataforma

Guia para repetir o mesmo laboratório em **Mac** e **Windows**: o que fica no repo, o que é local em cada máquina, e dependências.

A API Core/Vision é **online** (ou Docker local). O Device Lab desktop só orquestra SDK + emuladores + MITM no teu PC.

---

## Resumo

| Pergunta | Resposta |
|----------|----------|
| Setup salvo resolve? | **Sim**, em cada máquina: template AVD + APKs em `.local/` + `device-lab.yaml`. |
| Copiar AVD Mac → Windows? | **Não** (ARM vs x86). Setup **por plataforma**. |
| Mesmo app Java? | **Sim** (código igual). **Build** no OS destino (`.dmg` / `.exe`). |
| O que vai no git? | Código, scripts, `device-lab.yaml.example`, `env/devices.txt`. |
| O que não vai no git? | `.local/ddt-apk/`, pastas `~/.android/avd/`, keychain. |

---

## Dependências por sistema

### Todas as plataformas

| Ferramenta | Uso | Verificar |
|------------|-----|-----------|
| **Java 17+** | Device Lab desktop + CLI | `java -version` |
| **Maven 3.9+** | Compilar Device Lab | `mvn -version` |
| **Android SDK** | `adb`, `emulator` — **baixado pelo Device Lab** se não existir | `./device-lab doctor` |
| **Python 3** | Bridge DDT | `python3 --version` |
| **mitmproxy** | MITM (`mitmdump`) | `mitmdump --version` |
| **OpenSSL** | Certificados | `openssl version` |
| **scrcpy** | Ver emulador headless | `scrcpy --version` |

Instalar o que falta:

```bash
./device-lab install-deps
./device-lab doctor
```

### macOS (Apple Silicon)

| Item | Valor típico |
|------|----------------|
| SDK | `~/Library/Android/sdk` ou `ANDROID_HOME` |
| Emulador ABI | `arm64-v8a` (`avdProfile.abi: auto`) |
| AVDs | `~/.android/avd/` |
| Device Lab | `./device-lab` ou `.dmg` |

### macOS (Intel) / Windows / Linux

| Item | Valor típico |
|------|----------------|
| SDK Windows | `%LOCALAPPDATA%\Android\Sdk` ou `ANDROID_HOME` |
| Emulador ABI | `x86_64` (ou `arm64` em Windows ARM) |
| AVDs | `%USERPROFILE%\.android\avd\` (Windows) |
| Device Lab | `device-lab.bat gui` ou `.exe` após `jpackage` no Windows |

**Windows:** compilar o desktop no Windows (`mvn package` / jpackage). JavaFX usa libs nativas por OS.

---

## Ficheiros de configuração (repo)

| Ficheiro | Função |
|----------|--------|
| `device-lab.yaml` | API Core, lista de AVDs, perfil do emulador, portas mitm/bridge, path APKs do jogo |
| `device-lab.yaml.example` | Modelo — copiar e editar |
| `env/devices.txt` | Lista de AVDs (bootstrap + GUI). Actualizado pelo Device Lab |

### `device-lab.yaml` — campos importantes

```yaml
api:
  baseUrl: http://localhost:8082

devices:
  - avd: device-template    # template protegido (não apagar na GUI)
  - avd: device-01

templateAvd: device-template
cloneNamePrefix: device-

avdProfile:
  apiLevel: 30
  systemImageTag: default      # AOSP sem Play Store (mitm/cert)
  abi: auto                    # arm64 no Mac M*, x86_64 no Windows típico
  deviceProfile: pixel_4
  ramMb: 2048
  writableSystem: true         # cert em /system

mitm:
  port: 8888

bridge:
  port: 8799

game:
  packageId: com.road7.ddtankbr.gp
  apkPath: .local/ddt-apk/apk  # pasta no monorepo (não no git)

bot:
  packageId: com.automation.bot
```

---

## Artefactos locais (não no git)

### APKs do jogo DDT — `.local/ddt-apk/apk/`

O bot precisa de `com.road7.ddtankbr.gp` instalado no emulador.

| Ficheiro | Notas |
|----------|--------|
| `base.apk` | Obrigatório |
| `split_*.apk` | Splits do Play (assets, idioma, densidade) |
| `split_config.arm64_v8a.apk` | **Mac Apple Silicon** |
| `split_config.x86_64.apk` (ou x86) | **Windows Intel** |

Obter numa vez:

```bash
# Com jogo já instalado num device/emulador da MESMA arquitetura
./scripts/bot/pull-ddt-apk.sh pull
# Grava em .local/ddt-apk/apk/
```

No **Windows**, repetir `pull` num emulador Windows ou copiar a pasta com splits **x86**.

### APK Device Lab (worker) — build automático

- Fonte: `automation-bot-ddt/`
- Build: `cd automation-bot-ddt && ./gradlew assembleDebug`
- Turn On com checkbox compila se o APK não existe.

### Emuladores (AVD)

- Pasta: `~/.android/avd/` (Mac/Linux) ou `%USERPROFILE%\.android\avd\` (Windows)
- Cada AVD: `nome.ini` + `nome.avd/`
- **Template + duplicar**: um golden por máquina (`device-template`); clones via GUI **+ Duplicar** copiam `.ini` + `.avd/`.

**Não copiar** `.avd` entre Mac ARM e Windows x86.

---

## Fluxo Turn On (checkbox «Instalar DDT + Device Lab»)

1. Bootstrap: emulador headless + mitm + bridge + cert
2. `install-ddt-apk.sh` — jogo se ainda não instalado
3. `install-apk.sh` — app Device Lab se ainda não instalado; abre o app
4. Manual no Android: **Accessibility** Device Lab ON (uma vez por clone)

---

## Checklist — nova máquina (Mac ou Windows)

1. Clonar `automation-learn`
2. Instalar Java, Maven — **Android SDK**: o Device Lab baixa da Google na 1ª abertura (`.local/device-lab/android-sdk/`) ou usa Studio/`ANDROID_HOME` se já existir
3. `cp device-lab.yaml.example device-lab.yaml` e ajustar `api.baseUrl`
4. `./device-lab install-deps` e `./device-lab doctor` (tudo verde)
5. Colocar APKs DDT em `.local/ddt-apk/apk/` (ABI certa)
6. Abrir Device Lab — provisiona `device-template` se ausente (ou `./device-lab provision --avd device-template`)
7. Turn On no template com checkbox → instala jogo + Device Lab; configurar Accessibility
8. **+ Duplicar** → `device-01`, `device-02`… (copia do template)

### Build do desktop

```bash
# Mac
./device-lab package-dmg

# Windows (no Windows)
cd automation-device-lab
mvn package -DskipTests
# jpackage → .exe (ver package-dmg.sh adaptado)
```

---

## O que partilhar entre colegas / máquinas

| Partilhar | Como |
|-----------|------|
| Repo git | clone |
| `device-lab.yaml` | commit ou copiar (sem secrets) |
| APKs DDT | zip de `.local/ddt-apk/apk/` **da mesma arquitetura** |
| Template AVD | zip de `template.ini` + `template.avd/` **mesma arquitetura** |
| App desktop | instalador `.dmg` / `.exe` por OS |

---

## Comandos úteis

```bash
./device-lab                    # GUI
./device-lab doctor               # checklist
./device-lab provision --avd NOME # criar AVD
./scripts/bot/install-ddt-apk.sh emulator-5554
./scripts/bot/install-apk.sh emulator-5554
emulator -list-avds
```

Guia Windows: [BUILD-WINDOWS-EXE.md](BUILD-WINDOWS-EXE.md) · VM: [BUILD-WINDOWS-VM.md](BUILD-WINDOWS-VM.md)
