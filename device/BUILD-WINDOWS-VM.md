# Build do Device Lab no Windows (VM)

Guia rápido. Documentação completa: **[BUILD-WINDOWS-EXE.md](BUILD-WINDOWS-EXE.md)**.

## Resumo

```powershell
winget install Git.Git Microsoft.OpenJDK.21
git clone https://github.com/ConteLucas/automation-device-lab.git
cd automation-device-lab
copy device-lab.yaml.example device-lab.yaml
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\config\build-win.bat
```

**Resultado:** `release\Device-Lab-Setup.exe` (~39 MB)

Duplo-clique → assistente Windows (Next, pasta, atalho, Finish).

## Verificar toolchain

```powershell
.\.local\jdk-x64\bin\java.exe -version
.\.local\jdk-x64\bin\jpackage.exe --version
.\mvnw.cmd -version
```

Maven global **não é necessário** — use `mvnw.cmd`.

## Instalar / testar

```powershell
.\release\Device-Lab-Setup.exe
```

Ou em dev, sem instalador:

```powershell
.\device-lab.bat gui
```

## Problemas comuns

| Erro | Solução |
|------|---------|
| `jpackage` não encontrado | JDK completo 21+ (não só JRE) |
| JavaFX vazio | `mvn package` **no Windows** |
| Script bloqueado | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| App não abre após instalar | Rebuild com `.\config\build-win.bat` e reinstalar |

## macOS

`./build-mac.sh` → `target/dist/Device Lab-1.0.0.dmg`
