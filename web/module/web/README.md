# Documentação web — SuiteLAB

Visão do frontend (`automation-web-lab`) por módulo: o que cada LAB **é**, o que **oferece hoje** e como se conecta ao restante da suite.

| Módulo | URL principal | Documento |
|--------|---------------|-----------|
| **SuiteLAB** | `/menu`, `/admin` | [suite/README.md](./suite/README.md) |
| **MacroLAB** | `/macro` | [macro/README.md](./macro/README.md) |
| **MarketLAB** | `/marketplace` | [markt/README.md](./markt/README.md) |
| **ProviderLAB** | `/providers` | [provider/README.md](./provider/README.md) |

## Convenções usadas nesta pasta

- **Página A** — experiência logada (painel / app).
- **Página B** — experiência visitante (marketing / landing).
- Rotas e permissões refletem o código em `automation-web-lab/src` no estado atual, não roadmap.

## Auth compartilhada

Todos os módulos usam o mesmo `AuthContext` e token JWT. Cada LAB tem login próprio (`/macro/login`, `/marketplace/login`, `/providers/login`); o admin unificado usa `/login` ou sessão já ativa.

## Admin unificado

Operação administrativa dos três módulos converge em **`/admin`** (hub SuiteLAB). Detalhes em [suite/README.md](./suite/README.md).
