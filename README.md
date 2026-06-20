# Documentação — automation-learn

Documentação centralizada por serviço. **Não** commitar `docs/` nos repos de aplicação (`automation-core-lab`, `automation-bot-lab`, etc.).

## Estrutura

| Pasta | Serviço | Repo de código |
|-------|---------|----------------|
| [core/](core/) | Core API (Spring) | `automation-core-lab` |
| [vision/](vision/) | Vision / OCR | `automation-vision-lab` |
| [bot/](bot/) | Bot worker (Android) | `automation-bot-lab` |
| [device/](device/) | Device Lab desktop | `automation-device-lab` |
| [web/](web/) | Web UI (React) | `automation-web-lab` |

## Transversal

- [TECH-STORIES.md](TECH-STORIES.md) — histórias técnicas e stack
- [REPOSITORIES-OVERVIEW.md](REPOSITORIES-OVERVIEW.md) — visão multi-repo

## Infra / deploy

Deploy AWS, Terraform e compose de produção ficam em `automation-infra-lab/docs/`.

## SQL, seeds e modelo de dados

Centralizado em **`automation-db-lab`** — [README](../automation-db-lab/README.md).

## Documentação de domínio (API, segurança): [docs/core/](docs/core/) neste repo.

## Device Lab (docs no configs-lab)

| Documento | Conteúdo |
|-----------|----------|
| [docs/device/SETUP-MULTIPLATAFORMA.md](docs/device/SETUP-MULTIPLATAFORMA.md) | Setup Device Lab |
| [docs/device/BUILD-WINDOWS-EXE.md](docs/device/BUILD-WINDOWS-EXE.md) | Instalador Windows |
| [docs/device/BUILD-WINDOWS-VM.md](docs/device/BUILD-WINDOWS-VM.md) | Build na VM |

Código: [automation-device-lab](../automation-device-lab/README.md)
