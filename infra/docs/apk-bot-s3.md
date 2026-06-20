# App artifacts — Android + Desktop (S3)

Distribuição dos apps para Device Lab:
- Android (`automation-bot-lab`)
- Desktop macOS/Windows (`automation-device-lab`)

## Fluxo

```
1. Editar `automation-bot-lab/config/version.properties` (versionCode + versionName)
2. Build prod:  APP_ENV=prod ./gradlew assembleDebug
3. Upload S3:   ./scripts/upload-bot-apk.sh
4. Device Lab lê bot.apk.manifestUrl → baixa se emulador sem app ou versão antiga
```

## S3

| Objecto | Conteúdo |
|---------|----------|
| `apk/android/releases/{versionName}/android-{versionName}.apk` | APK Android |
| `apk/android/latest.json` | manifest Android (versionCode, downloadUrl, sha256) |
| `apk/win/releases/{versionName}/device-lab-{versionName}.exe` | instalador Windows |
| `apk/win/latest.json` | manifest Windows |
| `apk/mac/releases/{versionName}/device-lab-{versionName}.dmg` | instalador macOS |
| `apk/mac/latest.json` | manifest macOS |

Exemplo `latest.json`:

```json
{
  "versionCode": 2,
  "versionName": "1.0.1",
  "appEnv": "PROD",
  "sha256": "...",
  "downloadUrl": "https://BUCKET.s3.us-east-1.amazonaws.com/apk/android/releases/1.0.1/android-1.0.1.apk",
  "builtAt": "2026-06-18T12:00:00Z",
  "packageId": "com.automation.bot"
}
```

## Comandos

```bash
# Build + upload (repo bot)
cd automation-configs-lab
APP_ENV=prod ./bot-lab/scripts/upload-bot-apk.sh

# Atalho (já buildou)
./bot-lab/rebuild-bot.sh --prod --build-only --upload

# Só upload
SKIP_BUILD=1 APP_ENV=prod ./bot-lab/scripts/upload-bot-apk.sh

# Desktop macOS (usa último .dmg em automation-device-lab/target/dist)
PLATFORM=mac ./device-lab/scripts/upload-desktop-app.sh

# Desktop Windows (fornecendo .exe explicitamente)
PLATFORM=win DESKTOP_FILE="../automation-device-lab/target/dist-build/Device Lab-1.0.0.exe" \
  ./device-lab/scripts/upload-desktop-app.sh
```

## device-lab.yaml

```yaml
bot:
  packageId: com.automation.bot
  apk:
    manifestUrl: https://BUCKET.s3.us-east-1.amazonaws.com/apk/android/latest.json
    preferLocalBuild: true   # dev: APK local Gradle tem prioridade
```

## Download público

O Mac (Device Lab) faz HTTP GET no `downloadUrl`. Opções:

1. **Bucket policy** — leitura pública em `apk/android/*`, `apk/win/*`, `apk/mac/*` (recomendado lab)
2. **Nginx** — proxy `/downloads/bot/` → S3 (futuro)

Sem URL pública, o download no Mac falha — use `preferLocalBuild: true` em dev.

## Versão

Android usa `automation-bot-lab/config/version.properties`:

```properties
versionCode=2
versionName=1.0.1
```

Incrementar **versionCode** em cada release publicada; **versionName** é informativo.

Desktop (win/mac) usa versão no nome do arquivo (`Device Lab-x.y.z.exe/.dmg`) ou variável `APP_VERSION`.

O Device Lab compara `versionCode` instalado (`adb dumpsys package`) com o manifest.
