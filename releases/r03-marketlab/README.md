# R03 — MarketLAB

**Período:** 2026-06  
**Status:** concluída  
**Ambiente:** lab AWS + desenvolvimento local

---

## Objetivo

Abrir canal público (marketplace) para compradores e prestadores de serviços, separado do CRM MacroLAB, com catálogo, anúncios e chat.

---

## Entregas

- Rotas `/marketplace` no `automation-web-lab`
- APIs `/api/marketplace/*` no Core
- Perfis `CUSTOMER` e `SERVICE_PROVIDER` em `permission`
- Cadastro público: `/api/auth/register/marketplace`
- Tabelas `ads_service_provider`, `ads_service_provider_review`
- Campo `game_account.marketplace_featured`
- Carteira (`wallet`) para usuários marketplace
- Chat por listing (storage em paths lab/S3)
- Seeds atualizados em `automation-db-lab/seeds/permission-seed.json`

---

## Arquitetura

Ver [ARCHITECTURE.md](ARCHITECTURE.md) e [DATABASE.md](DATABASE.md).

---

## Próximo passo

[R04 — Produção e identidade](../r04-producao-identidade/README.md): domínio, HTTPS e OAuth Google.
