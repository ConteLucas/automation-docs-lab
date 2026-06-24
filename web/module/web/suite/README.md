# SuiteLAB

**SuiteLAB** é o hub da plataforma: um login, três módulos especializados e um painel admin centralizado.

| | |
|---|---|
| **URL principal** | `https://automation-device-lab.com/menu` (dev: `http://localhost:5174/menu`) |
| **Admin** | `/admin` |
| **Marca visual** | Ciano `#2ee6c6` · wordmark `Suite[LAB]` |
| **Código** | `automation-web-lab/src/pages/shared/Menu/`, `src/pages/suiteAdmin/` |

---

## O que é

SuiteLAB não é um produto operacional à parte — é a **camada de entrada** do ecossistema. O visitante entende o que existe (Market, Macro, Provider), escolhe onde ir e faz login no módulo certo. Para equipe interna (DEV/ADM), é também o **atalho único** para administrar os três LABs.

Produção: domínio raiz `automation-device-lab.com`. O app web é servido pelo `automation-web-lab` (Vite + React).

---

## O que o site oferece hoje

### Hub público (`/menu`)

- Hero com proposta da suite (“uma suite completa para o universo gamer”).
- Cards dos três módulos com descrição, features e CTA para cada LAB.
- Estatísticas de posicionamento (3 plataformas, foco em jogos).
- Header com links diretos para `/marketplace`, `/macro` e `/providers`.
- Modal **Entrar** que encaminha ao login do módulo escolhido (não há cadastro genérico na suite).

### Experiência logada no menu

- Atalho para o painel principal do usuário: `/macro` se tiver acesso operacional (`DEV`, `ADM`, `MANAGER`, `SELLER`); caso contrário `/marketplace`.
- Botão **Admin** no header para quem pode administrar algum módulo (`/admin`).
- Logout global.

### Admin unificado (`/admin`)

Hub com cards no estilo do design Suite (verde / roxo / laranja), um por módulo administrável:

| Card | Rota | Quem vê |
|------|------|---------|
| MarketLAB | `/admin/markt` | DEV/ADM (site) · MANAGER (por jogo) |
| MacroLAB | `/admin/macro` | DEV/ADM |
| ProviderLAB | `/admin/provider` | DEV/ADM |

Cada card só aparece se o usuário tiver permissão. Dentro de um módulo, o shell `SuiteAdminPageShell` mostra breadcrumb `Admin → [Módulo]` e botão **Módulos** para voltar ao hub.

**Sub-rotas admin** (resumo — detalhes nos READMEs de cada módulo):

- `/admin/macro/*` — usuários, dispositivos, flow, wallet
- `/admin/markt/*` — jogos do site, editor de página, painel por jogo
- `/admin/provider` — aprovação e moderação de prestadores

Rotas antigas redirecionam automaticamente (`/macro/admin/*`, `/marketplace/admin/*`, `/providers/admin`, `/admin/users`, `/admin/devices`).

### Serviços transversais

- **Chat / mensagens** — `InboxFab` flutuante e `/mensagens` (usuário logado).
- **Botão ← Suite** — canto inferior esquerdo em Macro, Market e Provider (`LabBackToSuiteLink`).
- **Recuperação de senha** — `/esqueci-senha`, `/reset-senha`.
- **Confirmação de e-mail** — `/confirmar-email` (link enviado por API).
- **OAuth** — callback em `/auth/oauth/callback` (Google, Discord, Facebook conforme backend).

### CRM legado (coexiste com MacroLAB moderno)

Rotas antigas ainda ativas sob shell `AppShell` + `/login`:

`/lab`, `/flow`, `/pedidos`, `/accounts`, `/customers`, `/tasks`, `/settings`, `/downloads`, etc.

Na prática são usadas por **DEV/ADM**; usuários só marketplace são redirecionados para `/marketplace`.

---

## Público-alvo

| Perfil | Uso típico |
|--------|------------|
| Visitante | Descobrir módulos em `/menu` |
| Qualquer logado | Navegar entre LABs; mensagens |
| DEV / ADM | `/admin` + CRM legado |
| MANAGER | `/admin` (Market por jogo) + Macro operacional |

---

## O que ainda não é (limitações atuais)

- `/menu` não é um dashboard unificado pós-login — após entrar, o usuário vai para o LAB do seu papel.
- Busca global “Buscar em toda a suite” do design ainda não está no header do menu.
- Stats dos cards admin no hub são textos fixos, não métricas ao vivo da API.

---

## Arquivos-chave

```
src/pages/shared/Menu/index.tsx
src/pages/suiteAdmin/SuiteAdminHub.tsx
src/pages/suiteAdmin/SuiteAdminPageShell.tsx
src/config/suiteAdminPaths.ts
src/components/LabBackToSuiteLink.tsx
src/components/chat/InboxFab.tsx
```
