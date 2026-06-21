# Changelog — R03

## Added

- UI MarketLAB (catálogo, serviços, persona comprador)
- `MarketplaceRegistrationService`, rotas de catálogo e service providers
- Tabelas `ads_service_provider`, `ads_service_provider_review`
- Permissões `CUSTOMER`, `SERVICE_PROVIDER`
- `game_account.marketplace_featured`
- Wallet para novos usuários marketplace
- Chat marketplace (legado listing + paths particionados)

## Changed

- `AuthInterceptor` — rotas públicas de catálogo e registro marketplace
- Seeds de permissão expandidos

## Database

Ver [DATABASE.md](DATABASE.md).

## Notas

- Terminologia: **prestador de serviços** (não "provider" na UI em português).
