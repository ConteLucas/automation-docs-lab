# R04 — Produção e identidade

**Período:** 2026-06  
**Status:** concluída  
**Ambiente:** produção — https://automation-device-lab.com

---

## Objetivo

Tornar o lab acessível por domínio próprio com HTTPS, login OAuth Google para compradores e reforçar o isolamento MacroLAB vs MarketLAB.

---

## Entregas

- Domínio **automation-device-lab.com** (Cloudflare DNS → EC2)
- TLS Let's Encrypt via nginx (`setup-https.sh`, templates SSL no `automation-web-lab`)
- Redirect HTTP → HTTPS na porta 443
- OAuth Google:
  - Core: `APP_OAUTH_GOOGLE_CLIENT_ID`, `APP_OAUTH_GOOGLE_CLIENT_SECRET`
  - Web: `VITE_OAUTH_GOOGLE_CLIENT_ID`, redirect `https://automation-device-lab.com/auth/oauth/callback`
- Seeds CUSTOMER + SERVICE_PROVIDER aplicados em produção
- Frontend: `CUSTOMER` redirecionado para `/marketplace`; sem acesso MacroLAB
- Cadastro marketplace simplificado: apenas **comprador** (prestador via solicitação posterior)
- Runbook: [infra/docs/DOMAIN-SETUP.md](../../infra/docs/DOMAIN-SETUP.md)

---

## Arquitetura

Ver [ARCHITECTURE.md](ARCHITECTURE.md).

---

## Pendências conhecidas (pós-R04)

- OAuth Discord e Facebook — código pronto; falta registrar apps e env vars (ver [core/OAUTH-SETUP.md](../../core/OAUTH-SETUP.md))
- Rotação do client secret Google se exposto em canal inseguro
- Monitoramento formal de uptime na instância micro
