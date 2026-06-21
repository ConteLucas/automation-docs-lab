# Índice — Web CRM (`automation-web-lab`)

Frontend React — pedidos, flows, devices, admin.

**Última atualização:** 2026-06-20

---

## Início rápido

| Documento | Conteúdo |
|-----------|----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Stack, rotas, integração Core |
| [ESTRUTURA-E-BOAS-PRATICAS.md](ESTRUTURA-E-BOAS-PRATICAS.md) | Pastas, convenções |
| [FRONTEND-TELAS-E-BACKEND.md](FRONTEND-TELAS-E-BACKEND.md) | Telas × endpoints |

---

## Flows e diagramas

| Documento | Conteúdo |
|-----------|----------|
| [DIAGRAMA-FLOW-TECNICO.md](DIAGRAMA-FLOW-TECNICO.md) | Editor L1–L4, GOTO, upload PNG |
| [VISUAL-VALIDATION-PROMPT.md](VISUAL-VALIDATION-PROMPT.md) | Prompt validação visual (IA) |
| [../FLOW-SYNC-E-S3.md](../FLOW-SYNC-E-S3.md) | O que acontece após salvar no BD/S3 |

---

## Produção e segurança

| Documento | Conteúdo |
|-----------|----------|
| [PRODUCTION.md](PRODUCTION.md) | Build, nginx, deploy |
| [SECURITY.md](SECURITY.md) | JWT, CORS, boas práticas |

---

## Por objetivo

**Editar flows** → [DIAGRAMA-FLOW-TECNICO.md](DIAGRAMA-FLOW-TECNICO.md) → [FLOW-CONTRACT.md](../../automation-db-lab/docs/FLOW-CONTRACT.md)

**Deploy frontend** → [PRODUCTION.md](PRODUCTION.md) → [../infra/docs/DEPLOY-DEV.md](../infra/docs/DEPLOY-DEV.md)

---

## Fluxo upload (resumo)

```text
Web → POST /flow-step-images/upload → Core grava S3 + retorna imagePath
Web → POST /flow-step-images → persiste no BD
Bump versão → Core espelha json/bot no S3 (automático)
```

Detalhe: [FLOW-SYNC-E-S3.md](../FLOW-SYNC-E-S3.md)
