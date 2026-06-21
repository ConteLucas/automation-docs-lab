# Changelog — R02

## Added

- Deploy produção lab em EC2 via Docker Compose
- Integração S3 para espelho de flows (sync a partir do Core)
- Documentação infra: `infra/ARCHITECTURE.md`, `DEPLOY-DEV.md`, `RESTART-INSTANCE.md`
- Variáveis `.env.prod` na instância (`/opt/automation-learn/.env.prod`)

## Changed

- Bot passa a consumir assets do S3 conforme `deployEnv`
- Web servida via container nginx na EC2

## Database

- Sem novas tabelas de negócio; Postgres na stack de produção

## Operação

- Deploy por serviço: `./deploy-service.sh infra|core|web|vision`
- Health checks e tempo de subida do Core em instância micro (~2 min após restart)
