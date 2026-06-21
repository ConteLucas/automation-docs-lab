# Changelog — R04

## Added

- Domínio `automation-device-lab.com` com certificado TLS
- `setup-https.sh`, `setup-domain.sh`
- Nginx entrypoint com templates `http-only` e `ssl`
- OAuth Google no Core e Web (produção)
- `permissionDisplayLabel`, guards `isMarketplaceUser`, `canAccessMacroLab`
- Documentação `infra/docs/DOMAIN-SETUP.md`

## Changed

- `docker-compose.prod.yml` — porta 443, vars OAuth, `APP_DOMAIN`
- `MarketplacePersona` — cadastro só como comprador
- `OAuthCallback` — redirect padrão `/marketplace`
- `MacroProtectedRoute` — bloqueio CUSTOMER no CRM

## Fixed

- 404 em `/api/auth/oauth` após deploy core desatualizado
- "Login com Google não configurado" — vars no compose
- "Perfil CUSTOMER não configurado" — seed de permissões em produção
- 502 transitório durante `deploy-all` (Core em health starting na t4g.micro)

## Database

- `user_admin.oauth_provider`, `user_admin.oauth_provider_id` (uso em produção)
- Permissões CUSTOMER e SERVICE_PROVIDER garantidas no Postgres de produção

Ver [DATABASE.md](DATABASE.md).
