# Configuração — automation-bot-lab

## Um arquivo, um switch

Tudo em **`application.properties`** na raiz (como os outros labs). Perfis no mesmo arquivo com prefixo:

```properties
app.env=local          # mude para dev ou prod

local.CORE_API_BASE_URL=http://10.0.2.2:8082/
prod.CORE_API_BASE_URL=http://automation-device-lab.com/
```

Template: `config/application.properties.example` → copiar para `application.properties`.

## Override sem editar o arquivo

CI / upload S3 pode forçar perfil sem mudar `app.env`:

```bash
./gradlew assembleDebug -PAPP_ENV=prod
APP_ENV=prod ./gradlew assembleDebug
```

`-PAPP_ENV` e `APP_ENV` têm prioridade sobre `app.env` no arquivo.

## Por que não YAML?

Gradle/Android injeta em `BuildConfig` no compile — `.properties` é nativo. Segredos: arquivo gitignored; valores ainda entram no APK.

## Chaves principais

- `CORE_API_BASE_URL`, `DEVICE_IDENTIFIER`, `DEVICE_API_KEY`
- `VISION_API_BASE_URL`, `VISION_API_KEY`
- `DDT_RUNTIME_BRIDGE_*`, `WORKER_*`

Seeds dev Core: `device-android-001` / `dev-device-key-001`.
