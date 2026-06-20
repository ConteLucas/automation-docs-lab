# Como gerar o executável Windows (.exe)

Guia para compilar o **Device Lab** e gerar o instalador em **`release/Device-Lab-Setup.exe`**.

> **Entrega:** o ficheiro que distribui está em `automation-device-lab/release/Device-Lab-Setup.exe` (ver README nessa pasta).

## Resultado do build (o que importa)

```
release/Device-Lab-Setup.exe    ← distribuir / enviar / instalar
```

| Artefacto | Caminho | Uso |
|-----------|---------|-----|
| **Instalador final** | `release\Device-Lab-Setup.exe` | **Distribuir** — duplo-clique no PC do utilizador |
| Cópia intermédia | `target\dist-exe\Device Lab-1.0.0.exe` | Gerado pelo jpackage; o build copia para `release\` |

O instalador:
- Mostra o **assistente Windows** (não é silencioso)
- Pergunta se quer **atalho no Ambiente de Trabalho**
- Instala por utilizador (`%LOCALAPPDATA%`)
- Cria entrada no **Menu Iniciar**
- **Inclui Java** — o utilizador final não precisa de JDK

Na primeira abertura, o app prepara automaticamente:

```
%USERPROFILE%\.automation-device-lab\lab\
```

(SDK, Python, mitmproxy e Scrcpy são descarregados depois, pela GUI.)

---

## Pré-requisitos (máquina de build)

Compile **no Windows** (x64 ou ARM64). Não copie a pasta `target\` de outro SO.

| Ferramenta | Obrigatório | Notas |
|------------|-------------|-------|
| **JDK 21+** (com `jpackage`) | Sim | O script baixa Temurin x64 para `.local\jdk-x64` se faltar |
| **Maven** | Não | Use `mvnw.cmd` na raiz |
| **WiX 3.x** | Sim para `jpackage --type exe` | Já incluído em `.local\wix` no repo |
| **Git** | Recomendado | Para clonar o repo |

Instalação rápida (opcional):

```powershell
winget install Git.Git Microsoft.OpenJDK.21
```

---

## Passo a passo

### 1. Clonar e entrar no repo

```powershell
git clone https://github.com/ConteLucas/automation-device-lab.git
cd automation-device-lab
```

### 2. Config local (só para compilar)

```powershell
copy device-lab.yaml.example device-lab.yaml
```

Edite `device-lab.yaml` se precisar mudar a API (`local` / `prod`). Este ficheiro **não vai para o git**; o build embute uma cópia no instalador.

### 3. Gerar o instalador

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\config\build-win.bat
```

Ou directamente:

```powershell
.\config\build-windows.ps1
```

O script:
1. Compila o JAR (`mvnw.cmd clean package -DskipTests`)
2. Copia `device-lab.yaml`, `assets/` e JavaFX para `target\jpackage-input`
3. Corre `jpackage --type exe` com atalhos e assistente Windows
4. Copia o resultado para `release\Device-Lab-Setup.exe`

Tempo típico: **3–6 minutos** (primeira vez pode demorar mais ao baixar o JDK).

### 4. Testar o instalador

```powershell
.\release\Device-Lab-Setup.exe
```

Siga o assistente. Depois abra **Device Lab** pelo Menu Iniciar ou Ambiente de Trabalho.

### 5. Testar sem instalar (desenvolvimento)

```powershell
.\device-lab.bat gui
```

Abre a GUI com `javaw` (sem janela preta do terminal). Comandos CLI (`doctor`, `auth login`, etc.) continuam a usar o terminal.

---

## Estrutura dos scripts

```
build-win.bat              → config\build-win.bat → config\build-windows.ps1
config\build-windows.ps1   → build completo (Maven + jpackage exe)
config\device-lab.bat        → correr JAR em dev (gui / CLI)
config\install-from-app.ps1  → instalação manual da app-image (legado/portátil)
instalar-device-lab.bat      → corre o Setup.exe ou instalação directa
```

---

## Variáveis opcionais

```powershell
# Usar outro device-lab.yaml no pacote (em vez do da raiz)
$env:DEVICE_LAB_CONFIG = "C:\caminho\meu-device-lab.yaml"
.\config\build-win.bat
```

---

## Problemas comuns

| Sintoma | Causa provável | Solução |
|---------|----------------|---------|
| App abre e fecha logo | Build antigo sem `java.logging` | `.\config\build-win.bat` de novo e reinstalar |
| Janela preta ao abrir | Abriu `java.exe` ou `.bat` no terminal | Use o atalho **Device Lab** ou `device-lab.bat gui` |
| `jpackage` não encontrado | Só JRE instalado | Instale JDK 21+ ou deixe o script baixar para `.local\jdk-x64` |
| JavaFX vazio / erro GUI | `target\` copiado do Mac | Apague `target\` e compile **no Windows** |
| `Device-Lab-Setup.exe` bloqueado ao rebuild | Instalador ainda aberto | Feche o Setup.exe e o Device Lab; volte a correr o build |
| SmartScreen bloqueia o .exe | App não assinada | **Mais informações** → **Executar mesmo assim** |
| Permissão negada em `Programs\Device Lab` | Versão antiga usava pasta da app como lab | Reinstale com o build novo; dados em `~\.automation-device-lab\lab` |

---

## macOS

No Mac, use:

```bash
./build-mac.sh
open "target/dist/Device Lab-1.0.0.dmg"
```

---

## Resumo de uma linha

```powershell
copy device-lab.yaml.example device-lab.yaml; .\config\build-win.bat
# → release\Device-Lab-Setup.exe
```
