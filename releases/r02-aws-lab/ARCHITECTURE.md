# Arquitetura — R02 (AWS Lab)

```mermaid
graph TB
    subgraph aws["AWS"]
        EC2["EC2 t4g.micro"]
        S3["S3\nmacros + json/bot\npor deployEnv"]
        PG[("PostgreSQL 15\ncontainer ou host")]
    end

    subgraph ec2_stack["Docker Compose na EC2"]
        NGINX[nginx / web :80]
        CORE[core :8081]
        VISION[vision :8000]
    end

  subgraph clients["Clientes"]
        WEB_USER[Navegador CRM]
        BOT[Bot Android]
    end

    WEB_USER --> NGINX
    NGINX --> CORE
    BOT --> CORE
    BOT --> VISION
    CORE --> PG
    CORE -->|IAM role| S3
```

## Ambientes de deploy (S3)

| Env | Uso |
|-----|-----|
| LOCAL | Desenvolvimento |
| HMG | Homologação |
| PROD | Lab EC2 |

Path pattern documentado em [FLOW-SYNC-E-S3.md](../../FLOW-SYNC-E-S3.md).

## Infra como código

- `automation-infra-lab` — Terraform, compose templates
- `automation-configs-lab/infra-lab/scripts/` — operação diária
