# Arquitetura — R01 (monorepo)

Organização de repositórios; runtime igual a R00.

```mermaid
graph TB
    subgraph repos["Monorepo automation-learn"]
        CORE[automation-core-lab]
        WEB[automation-web-lab]
        BOT[automation-bot-lab]
        VISION[automation-vision-lab]
        INFRA[automation-infra-lab]
        CFG[automation-configs-lab]
        DOCS[automation-docs-lab]
        DB[automation-db-lab]
        DEVLAB[automation-device-lab]
    end

    DOCS -.->|documenta| CORE & WEB & BOT & INFRA
    CFG -.->|scripts deploy| INFRA
```

## Convenções estabelecidas

- Um índice `INDEX.md` por área em `automation-docs-lab`
- Scripts operacionais em `automation-configs-lab/infra-lab/scripts/`
- DDL e seeds em `automation-db-lab`
