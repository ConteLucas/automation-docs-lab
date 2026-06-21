# Proposta do produto — módulos e escopo

**Última atualização:** 2026-06-21  
Complementa a [visão](VISION.md) com escopo funcional por área.

---

## 1. MacroLAB — operação e automação

**Proposta:** Centralizar a criação de pedidos, geração de tasks e monitoramento de execução em dispositivos Android.

| Capacidade | Descrição | Release |
|------------|-----------|---------|
| Catálogo de jogo | Ranges (1–65 servidores), contas, detalhes por servidor | R00 |
| Pedidos de venda | `sales_order` + tipos ACC15/ACC30, prioridade, status | R00 |
| Geração de tasks | N tasks por pedido conforme range e contas disponíveis | R00 |
| Flows editáveis | `flow` / `flow_step` / `flow_step_image`, worker actions | R00–R01 |
| Sync para S3 | Core publica JSON/macros por `deployEnv` | R02 |
| Device registry | API Key por device, claim-next | R00 |
| RBAC interno | ADM, DEV, MANAGER, SELLER | R00 |

**Não inclui (Macro):** cadastro público anônimo; isso é MarketLAB.

---

## 2. MarketLAB — marketplace público

**Proposta:** Canal de aquisição e serviços para o ecossistema, sem expor o CRM.

| Capacidade | Descrição | Release |
|------------|-----------|---------|
| Catálogo público | Listagem de contas/itens publicados | R03 |
| Cadastro comprador | Registro público como CUSTOMER | R03 |
| OAuth | Login Google (produção); senha local em dev | R04 |
| Prestador de serviços | Cadastro inicial como comprador → solicitação em Serviços | R03–R04 |
| Anúncios prestador | `ads_service_provider`, reviews, destaque | R03 |
| Chat marketplace | Mensagens por listing (storage em path lab) | R03 |
| Carteira | Wallet para fluxos de pagamento futuros | R03 |

**Regra de acesso (R04):** `CUSTOMER` e `SERVICE_PROVIDER` são redirecionados para `/marketplace`; rotas MacroLAB bloqueadas no frontend e validadas no Core.

---

## 3. Bot & Vision — execução

| Capacidade | Descrição | Release |
|------------|-----------|---------|
| UIAutomator2 | Automação nativa Android | R00 |
| Claim / status | Polling Core, atualização de `flow_step_id` | R00 |
| Templates S3 | Imagens de steps baixadas do espelho S3 | R02 |
| Vision API | OCR / match opcional via `automation-vision-lab` | R00 |

---

## 4. Device Lab — desktop

| Capacidade | Descrição | Release |
|------------|-----------|---------|
| Instalador Windows | `Device-Lab-Setup.exe` | R01 |
| Emparelhamento | Provisiona device no Core com JWT admin | R00 |

---

## 5. Infra & deploy

| Capacidade | Descrição | Release |
|------------|-----------|---------|
| Compose prod | Core + Web + Vision + Postgres na EC2 | R02 |
| Scripts deploy | `deploy-service.sh`, bootstrap | R01–R02 |
| Domínio + TLS | Nginx, Let's Encrypt, redirect HTTP→HTTPS | R04 |
| Variáveis OAuth | `APP_OAUTH_*` no Core, `VITE_OAUTH_*` no Web | R04 |

---

## Matriz release × repositório

| Repo | R00 | R01 | R02 | R03 | R04 |
|------|:---:|:---:|:---:|:---:|:---:|
| automation-core-lab | ● | ● | ● | ● | ● |
| automation-web-lab | ● | ● | | ● | ● |
| automation-bot-lab | ● | ● | ● | | |
| automation-vision-lab | ● | ● | ● | | |
| automation-infra-lab | | ● | ● | | ● |
| automation-configs-lab | | ● | ● | | ● |
| automation-docs-lab | | ● | ● | ● | ● |
| automation-db-lab | ● | ● | ● | ● | ● |
| automation-device-lab | ● | ● | | | |

---

## Critérios de “release documentada”

Uma release entra no [INDEX](../releases/INDEX.md) quando:

1. Há entrega verificável (deploy, feature ou mudança de schema).
2. `CHANGELOG.md` e `README.md` existem na pasta `rNN-*`.
3. Deltas de banco e arquitetura estão refletidos (nesta pasta ou em `db/ARCHITECTURE.md` global).
