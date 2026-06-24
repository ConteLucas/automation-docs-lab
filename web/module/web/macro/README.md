# MacroLAB

**MacroLAB** é o painel operacional da equipe: contas de jogo, pedidos, tarefas de automação, dispositivos worker e carteira interna.

| | |
|---|---|
| **URL principal** | `/macro` |
| **Login** | `/macro/login` |
| **Admin (via Suite)** | `/admin/macro` |
| **Marca visual** | Roxo `#b79cff` / `#C8A0FF` · wordmark `Macro[LAB]` |
| **Código** | `automation-web-lab/src/pages/macrolab/` |

---

## O que é

MacroLAB é o **back-office de automação**: onde vendedores e gestores acompanham bots, pedidos e contas; onde DEV/ADM configuram flows, devices e usuários. Não é marketplace público — compradores (`CUSTOMER`) e prestadores (`SERVICE_PROVIDER`) veem apenas a **landing de marketing** em `/macro`, sem acesso ao painel.

---

## Página A vs página B (`/macro`)

| Estado | O que vê |
|--------|----------|
| **B — Visitante** ou sem `canAccessMacroLab` | `MacroLanding`: hero de automação, rotinas populares (mock), empty state de bots, CTA para login |
| **A — Logado** (`DEV`, `ADM`, `MANAGER`, `SELLER`) | `MacroHome`: stats de tarefas, bots em execução, atalhos operacionais |

`MacroIndexRoute` decide automaticamente. Shell: `MacroLayout` com `shellMode: 'guest' | 'app'`.

---

## O que o site oferece hoje

### Painel operacional (autenticado)

Rotas em `/macro/*`, protegidas por `MacroProtectedRoute`:

| Rota | Função |
|------|--------|
| `/macro` | Home / dashboard |
| `/macro/accounts` | Gestão de contas de jogo (AccountGame) |
| `/macro/pedidos` | Lista e criação de pedidos |
| `/macro/tarefas` | Tarefas de automação (status, fila) |
| `/macro/wallet` | Carteira operacional |
| `/macro/clientes` | CRM de clientes |
| `/macro/configuracoes` | Perfil, senha, confirmação de e-mail |
| `/macro/notificacoes` | Notificações |

**Nav** filtrada por permissão (ex.: wallet só para quem `canAccessWallet`; accounts para quem `canAccessGameAccounts`).

**Header:** busca interna (`MacroHeaderSearch`), chat de suporte (`LabChatPanel`), notificações, link **Admin** → `/admin` (DEV/ADM).

### Admin MacroLAB (`/admin/macro`)

| Rota | Função | Permissão |
|------|--------|-----------|
| `/admin/macro` | Visão geral: stats, downloads desktop, atalhos | DEV/ADM |
| `/admin/macro/usuarios` | Administração de usuários | DEV/ADM/MANAGER |
| `/admin/macro/dispositivos` | Dispositivos worker | DEV/ADM |
| `/admin/macro/flow` | Editor de fluxos de automação | **somente DEV** |
| `/admin/macro/wallet` | Crédito manual na carteira | DEV/ADM |

`MacroAdminShell` organiza navegação **Sistema** + painéis CRM embutidos (pedidos, tarefas, accounts, clientes via query `?crm=`).

Breadcrumb: `Admin → MacroLAB → [seção]`.

### Login e cadastro

- `/macro/login` — login por usuário/senha; OAuth se habilitado.
- **Cadastro público desabilitado** na UI (“acesso sob convite”).
- Sem login em rota protegida → `/macro/login` com `state.from` para retorno.

---

## Público-alvo

| Role | Acesso |
|------|--------|
| DEV | Painel completo + flow + admin |
| ADM | Painel + admin (sem flow) |
| MANAGER | Painel + usuários (admin) |
| SELLER | Painel operacional (pedidos, accounts conforme regra) |
| CUSTOMER / SERVICE_PROVIDER | Apenas landing B em `/macro` |

---

## Integração com outros módulos

- **SuiteLAB** — botão ← Suite; admin via `/admin`.
- **MarketLAB** — `MacroGameDashboard` reutilizado em `/admin/markt/:gameSlug` (painel por jogo).
- **Wallet API** — mesma base de carteira usada no marketplace (escopos diferentes).
- Usuários **só marketplace** que tentam CRM legado (`/lab`, `/pedidos`…) são enviados para `/marketplace`.

---

## O que ainda não é (limitações atuais)

- Landing B usa dados estáticos/mock em rotinas populares (não reflete API em tempo real).
- CRM legado (`/lab`, `/flow`, …) duplica parte das telas modernas em `/macro` — migração em andamento.
- Macro não tem landing de cadastro self-service.

---

## Arquivos-chave

```
src/pages/macrolab/configs/MacroIndexRoute.tsx
src/pages/macrolab/configs/MacroLanding.tsx
src/pages/macrolab/dashboard/MacroHome.tsx
src/pages/macrolab/configs/MacroLayout.tsx
src/pages/macrolab/admin/MacroAdminShell.tsx
src/pages/macrolab/dashboard/MacroSettings.tsx
```
