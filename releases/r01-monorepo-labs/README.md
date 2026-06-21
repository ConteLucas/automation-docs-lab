# R01 — Monorepo labs

**Período:** 2026-06  
**Status:** concluída  
**Ambiente:** local + repos separados no monorepo

---

## Objetivo

Padronizar nomenclatura `automation-*-lab`, extrair configs/scripts compartilhados e centralizar documentação em `automation-docs-lab`.

---

## Entregas

- Renomeação / organização: `automation-core-lab`, `automation-web-lab`, `automation-bot-lab`, `automation-vision-lab`, `automation-infra-lab`, `automation-configs-lab`, `automation-docs-lab`, `automation-device-lab`, `automation-db-lab`
- `automation-configs-lab` — bootstrap, scripts de deploy, build Device Lab
- Índices por sistema em `automation-docs-lab/{core,bot,web,...}/INDEX.md`
- Regra: docs de aplicação não vivem nos repos de código (apenas em `automation-docs-lab`)
- Device Lab: instalador Windows documentado em `automation-device-lab/release/`

---

## Arquitetura

Ver [ARCHITECTURE.md](ARCHITECTURE.md). Mesma topologia lógica de R00; mudança é **organizacional** (repos e docs).

---

## Próximo passo

[R02 — AWS Lab](../r02-aws-lab/README.md): subir stack na EC2.
