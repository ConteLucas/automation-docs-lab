# automation-device-lab — Arquitetura

Ferramenta desktop **local** (Java + GUI) para gerenciar o laboratório de dispositivos Android da plataforma DDT. Controla AVDs (emuladores), autentica e emparelha bots, captura logs e gerencia o SDK Android — sem subir infraestrutura Docker.

---

## Visão Macro

```mermaid
graph TB
    subgraph device_lab["automation-device-lab (Java Desktop App)"]
        direction TB

        subgraph ui["Interface"]
            GUI["GUI (JavaFX / Swing)\nmodo gráfico"]
            CLI["CLI\nmodo headless\n(doctor, provision...)"]
        end

        subgraph core_dl["Core"]
            AUTH["Auth Module\nlogin no Core API\ncredenciais do device"]
            SDK["Android SDK Manager\ndetecta adb, emulator"]
            AVD["AVD Manager\ncria/inicia AVDs\n(device-lab.avd)"]
            BRIDGE["Bridge / Pairing\nregistra device no Core\ntroca de API key"]
            LOGS["Log Viewer\nlogcat ao vivo"]
            MITM["MITM Support\nproxy HTTP para debug"]
        end

        subgraph config["Configuração"]
            YAML["device-lab.yaml\n(local, gitignored)\nAPI URL, perfil, AVD settings"]
            ENV_VAR["DEVICE_LAB_API_URL\nDEVICE_LAB_API_PROFILE\n(override env)"]
        end
    end

    subgraph external["Externos"]
        CORE_API["Core API\nSpring Boot :8080\n(online — sem Docker local)"]
        ADB["adb (Android Debug Bridge)\nAndroid SDK local"]
        AVD_EMU["Android Emulator\n(qemu-based)"]
    end

    GUI & CLI --> AUTH & SDK & AVD & BRIDGE & LOGS & MITM
    AUTH -->|POST /api/auth/login\nPOST /api/devices/provision| CORE_API
    BRIDGE -->|registra device + API key| CORE_API
    SDK --> ADB
    AVD --> AVD_EMU
    LOGS --> ADB
    YAML & ENV_VAR --> AUTH & SDK & AVD

    style device_lab fill:#d1fae5,stroke:#059669
    style external fill:#f3f4f6,stroke:#9ca3af
```

---

## Fluxo de Provisionamento de Device

```mermaid
sequenceDiagram
    participant DEV as Desenvolvedor
    participant DL as Device Lab (Desktop)
    participant ADB as adb
    participant EMU as Emulador Android
    participant CORE as Core API

    DEV->>DL: ./config/device-lab.sh gui
    DL->>DL: lê device-lab.yaml
    DL->>CORE: POST /api/auth/login (credenciais admin)
    CORE-->>DL: JWT token

    DEV->>DL: "Criar AVD" ou "Iniciar emulador"
    DL->>ADB: avdmanager create avd --name device-lab
    ADB-->>DL: AVD criado em device-lab.avd/
    DL->>EMU: emulator @device-lab -no-window
    EMU-->>DL: emulador online (serial emulator-5554)

    DEV->>DL: "Emparelhar device"
    DL->>CORE: POST /api/devices/provision {identifier, name}
    CORE-->>DL: {deviceId, apiKey}
    DL->>DL: salva apiKey em device-lab.yaml (ou config local)

    Note over DL,EMU: Device provisionado — Bot pode usar deviceId + apiKey
    DEV->>EMU: instala APK do bot → configura URL + apiKey
```

---

## Modo de Uso (CLI vs GUI)

```mermaid
graph LR
    subgraph cli["CLI (sem GUI)"]
        D["doctor\n(verifica SDK, adb, AVD)"]
        P["provision\n(registra device no Core)"]
        S["start-avd\n(inicia emulador)"]
        L["logs\n(logcat em tempo real)"]
    end

    subgraph gui_mode["GUI"]
        PANEL["Painel visual\n(botões para cada operação)"]
        LOG_VIEW["Viewer de logs ao vivo"]
        AVD_MGR["Gerenciador de AVDs"]
        AUTH_UI["Login no Core API"]
    end

    ENTRY["device-lab.sh / device-lab.bat"] --> cli & gui_mode
```

---

## Build e Distribuição

```mermaid
graph TD
    SOURCE["Código Java (src/)\n+ device-lab.yaml.example"]

    subgraph mac["macOS"]
        MVN_MAC["./config/device-lab.sh build\nmvnw clean package"]
        DMG["config/build-mac.sh\n→ automation-device-lab.dmg"]
    end

    subgraph win["Windows"]
        MVN_WIN["config\\device-lab.bat build\nmvnw.cmd clean package"]
        EXE["config\\build-win.bat\n(jpackage + WiX Toolset)\n→ release/Device-Lab-Setup.exe"]
    end

    SOURCE --> MVN_MAC & MVN_WIN
    MVN_MAC --> DMG
    MVN_WIN --> EXE

    NOTE["release/Device-Lab-Setup.exe\n(instalador Windows atual — distribuível)"]
    EXE --> NOTE
```

---

## Configuração (device-lab.yaml)

```yaml
# device-lab.yaml (gitignored — copiar de device-lab.yaml.example)
api:
  url: http://localhost:8082/api    # Core API URL
  profile: local                    # local | prod

device:
  identifier: device-android-001    # ID único do device
  name: "Emulador Lab 1"

avd:
  name: device-lab                  # nome do AVD
  sdk: 33                           # Android SDK version
  abi: x86_64

mitm:
  enabled: false
  port: 8888
```

Override via env: `DEVICE_LAB_API_URL=http://prod-server/api` ou `DEVICE_LAB_API_PROFILE=prod`.

---

## Estrutura do Repositório

```
automation-device-lab/
├── src/main/java/com/automation/devicelab/   # código Java
├── pom.xml                                    # build Maven
├── mvnw.cmd / mvnw                            # Maven wrapper
├── device-lab.yaml.example                   # template de config
├── device-lab.yaml                           # config local (gitignored)
├── config/
│   ├── device-lab.sh     # entry point Mac/Linux (gui/cli)
│   ├── device-lab.bat    # entry point Windows
│   ├── build-mac.sh      # gera .dmg
│   ├── build-win.bat     # gera .exe (Windows)
│   └── build-win.ps1     # alternativa PowerShell
├── packaging/
│   └── icons/            # ícones do app desktop
└── release/
    ├── Device-Lab-Setup.exe  # instalador Windows atual
    ├── README.md
    └── deprecado/            # scripts e builds antigos (ver LEGACY.md)
```

---

## Integração com Core API

| Operação | Endpoint | Auth |
|----------|----------|------|
| Login admin | `POST /api/auth/login` | — |
| Provisionar device | `POST /api/devices/provision` | JWT admin |
| Listar devices | `GET /api/devices` | JWT admin |
| Verificar saúde | `GET /health` | — |

---

## Tecnologias

| Item | Tecnologia |
|------|-----------|
| Linguagem | Java 17 |
| Build | Maven (mvnw) |
| UI | JavaFX ou Swing |
| Distribuição Windows | jpackage + WiX Toolset (`Device-Lab-Setup.exe`) |
| Distribuição macOS | jpackage (`.dmg`) |
| Config | YAML (device-lab.yaml) |
| Android | adb (Android Debug Bridge) |
