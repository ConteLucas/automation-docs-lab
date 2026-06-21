# R02 — AWS Lab (produção inicial)

**Período:** 2026-06  
**Status:** concluída  
**Ambiente:** AWS EC2 `54.225.198.82` (t4g.micro), Docker Compose

---

## Objetivo

Executar Core, Web, Vision e PostgreSQL na nuvem com custo mínimo (free tier) e espelhar flows/macros no S3 por ambiente de deploy.

---

## Entregas

- Terraform / compose em `automation-infra-lab`
- `docker-compose.prod.yml` — stack unificada na EC2
- Scripts: `deploy-service.sh`, bootstrap em `automation-configs-lab`
- Fluxo **BD → Core → S3 → Bot** documentado em [FLOW-SYNC-E-S3.md](../../FLOW-SYNC-E-S3.md)
- Acesso inicial por IP público (HTTP porta 80)
- Runbooks: [infra/docs/DEPLOY-DEV.md](../../infra/docs/DEPLOY-DEV.md), [RESTART-INSTANCE.md](../../infra/docs/RESTART-INSTANCE.md)

---

## Arquitetura

Ver [ARCHITECTURE.md](ARCHITECTURE.md).

---

## Próximo passo

[R03 — MarketLAB](../r03-marketlab/README.md): marketplace e novos perfis de usuário.
