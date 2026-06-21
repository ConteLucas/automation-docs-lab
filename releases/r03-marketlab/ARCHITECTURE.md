# Arquitetura — R03 (MarketLAB)

```mermaid
graph TB
    subgraph macro["MacroLAB — interno"]
        OP[ADM / DEV / MANAGER / SELLER]
        MACRO_UI[Web CRM /]
        OP --> MACRO_UI
    end

    subgraph market["MarketLAB — público"]
        CUST[CUSTOMER comprador]
        SP[SERVICE_PROVIDER prestador]
        MKT_UI[Web /marketplace]
        CUST --> MKT_UI
        SP --> MKT_UI
    end

    MACRO_UI --> CORE[Core API]
    MKT_UI --> CORE

    CORE --> PG[(PostgreSQL)]
    CORE --> CHAT[Chat paths\nmarketlab/chat]
```

## Separação de acesso

| Perfil | MacroLAB | MarketLAB |
|--------|:--------:|:---------:|
| ADM, DEV, MANAGER, SELLER | ✓ | opcional |
| CUSTOMER | ✗ | ✓ |
| SERVICE_PROVIDER | ✗ | ✓ (+ perfil prestador após aprovação) |

## Fluxo prestador de serviços

1. Cadastro público como **comprador** (CUSTOMER)
2. Navega em **Serviços** e solicita tornar-se prestador
3. Após aprovação → perfil `SERVICE_PROVIDER` + registro em `ads_service_provider`
