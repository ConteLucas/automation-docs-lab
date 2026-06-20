# Telas do frontend e conexão com o backend

Este documento descreve cada tela do app (automation-app-web), o que ela faz e quais endpoints da API (automation-core-ddt) usa. A base URL da API no front é `/api` (proxy para o backend).

---

## Roteamento (App.tsx)

| Rota | Componente | Protegida |
|------|------------|-----------|
| `/login` | Login | Não |
| `/` | DashboardHome | Sim |
| `/flow` | FlowManagement | Sim |
| `/flow/:stepId/imagens` | FlowStepImages | Sim |
| `/pedidos` | SalesOrderList | Sim |
| `/pedidos/novo` | NewOrder | Sim |
| `/accounts` | Accounts | Sim |
| `/customers` | Customers | Sim |
| `/tasks` | Tasks | Sim |
| `/settings` | Settings | Sim |
| `/admin/users` | AdminUsers | Sim |
| `/notifications` | Notifications | Sim |

Redirecionamentos: `/flow-management` → `/flow`, `/gerar-pedido` e `/ordens` → `/pedidos`, `/admin` → `/admin/users`.

---

## 1. Login (`/login`)

**Arquivo:** `pages/Login.tsx`

**O que faz:** Formulário de login (usuário e senha). Em sucesso, guarda o token no `localStorage` e redireciona para a rota de origem ou `/`.

**Backend:**
- `POST /api/auth/login` — body: `{ login, password }`; retorna `{ token, ... }`. O front persiste o objeto no `localStorage` e usa o token no header `Authorization: Bearer <token>` em todas as requisições protegidas.

---

## 2. Dashboard / Início (`/`)

**Arquivo:** `pages/DashboardHome.tsx`

**O que faz:** Página inicial após login. Lista resumo de pedidos de venda e links rápidos (Flow, Pedidos, Gerar pedido, etc.).

**Backend:**
- `GET /api/sales-orders` — lista pedidos; usado para exibir resumo no dashboard.

---

## 3. Flow Management (`/flow`)

**Arquivo:** `pages/FlowManagement.tsx`

**O que faz:**
- **Sem card selecionado:** Lista de flows (cards) em ordem de execução — cada linha é um `flow_key` (ex.: flow_local, LOGIN), com contagem de etapas e botão “Ver etapas”.
- **Com card selecionado:** Mostra as etapas (`flow_step`) daquele flow em vista Diagrama ou Lista; em cada etapa é possível adicionar/editar/excluir imagens (`flow_step_image`). Link “Ver página de imagens” leva para `/flow/:stepId/imagens`.

**Backend:**
- `GET /api/flow-steps` — lista todas as etapas (flow_step).
- `GET /api/flow-step-images` — lista todas as imagens (flow_step_image); o front agrupa por `flowStep.id`.
- `POST /api/flow-step-images/upload` — upload de arquivo (multipart); parâmetro opcional `flowKey`; retorna `{ imagePath }`.
- `POST /api/flow-step-images` — cria registro em flow_step_image (flowStepId, stepImgNumber, imagePath, coordinates, width, height).
- `PUT /api/flow-step-images/:id` — atualiza flow_step_image.
- `DELETE /api/flow-step-images/:id` — remove flow_step_image.

**Observação:** O “flow ativo” hoje vem da variável de ambiente `VITE_ACTIVE_FLOW_GROUP` (ex.: flow_local), apenas para exibir no header; não filtra dados no backend.

---

## 4. Flow Step Images (`/flow/:stepId/imagens`)

**Arquivo:** `pages/FlowStepImages.tsx`

**O que faz:** Página dedicada a uma etapa (flow_step). Exibe nome da etapa, diagrama visual (etapa + imagens em ordem), tabela de imagens (flow_step_image) com CRUD completo (adicionar com upload, editar, excluir).

**Backend:**
- `GET /api/flow-steps/:id` — busca a etapa (flow_step) pelo id.
- `GET /api/flow-step-images/by-step/:flowStepId` — lista imagens da etapa.
- `GET /api/flow-step-images/:id/file` — retorna o arquivo da imagem (blob) para exibir preview.
- `POST /api/flow-step-images/upload` + `POST /api/flow-step-images` — adicionar nova imagem (upload + criar registro).
- `PUT /api/flow-step-images/:id` — editar imagem.
- `DELETE /api/flow-step-images/:id` — excluir imagem.

---

## 5. Listar Pedidos (`/pedidos`)

**Arquivo:** `pages/SalesOrderList.tsx`

**O que faz:** Lista pedidos de venda (sales_order) do usuário logado, com abas/filtros e modal de edição (prioridade, etc.).

**Backend:**
- `GET /api/sales-orders?userAdminId=:id` — lista pedidos (filtrando por usuário quando aplicável).
- `GET /api/sales-orders/:id` — detalhe de um pedido.
- `PUT /api/sales-orders/:id` — atualiza pedido (ex.: prioridade, status).
- `DELETE /api/sales-orders/:id` — exclui pedido.

---

## 6. Gerar Pedido (`/pedidos/novo`)

**Arquivo:** `pages/NewOrder.tsx`

**O que faz:** Formulário para criar cliente (opcional) e pedido de venda (sales_order). Usa clientes e range servers para montar o payload.

**Backend:**
- `GET /api/customers` — lista clientes.
- `GET /api/range-servers` — lista range servers.
- `POST /api/customers` — cria cliente (se necessário).
- `POST /api/sales-orders` — cria pedido (sales_order).

---

## 7. Game Accounts (`/accounts`)

**Arquivo:** `pages/Accounts.tsx`

**O que faz:** Lista contas de jogo (game_account) com detalhes (game_details_account): login, senha (mascarada), server, level, nickname, status. Permite criar conta, editar (com campos bloqueados por cadeado até confirmar), excluir, importar CSV (placeholder), download CSV, paginação.

**Backend:**
- `GET /api/game-accounts` — lista game_account.
- `GET /api/game-details-accounts` — lista game_details_account; o front faz merge por gameAccountId.
- `POST /api/game-accounts` — cria game_account (login único).
- `PUT /api/game-accounts/:id` — atualiza game_account (login, senha).
- `PUT /api/game-details-accounts/:id` ou `POST /api/game-details-accounts` — atualiza/cria detalhes (server, nick, level).
- `DELETE /api/game-accounts/:id` — exclui game_account.

---

## 8. Tasks (`/tasks`)

**Arquivo:** `pages/Tasks.tsx`

**O que faz:** Tela de tarefas (task). Pode listar/buscar tarefas (conforme implementação atual).

**Backend:** Depende da implementação; tipicamente `GET /api/tasks` ou equivalente no core (não listado no client atual).

---

## 9. Configurações (`/settings`)

**Arquivo:** `pages/Settings.tsx`

**O que faz:** Abas Perfil (nome, avatar), Segurança (alterar senha: senha atual, nova, confirmar; medidor de força; ícone olho), Preferências (dark mode). Mensagens de erro com botão fechar e auto-dismiss em 5s.

**Backend:**
- `GET /api/auth/me` — perfil do usuário logado (MyProfileResponse).
- `PUT /api/auth/me` — atualiza nome.
- `PUT /api/auth/me/password` — altera senha (currentPassword, newPassword). Backend valida senha atual pelo usuário da sessão.

---

## 10. Admin Usuários (`/admin/users`)

**Arquivo:** `pages/AdminUsers.tsx`

**O que faz:** Gestão de usuários administradores (lista, criar, editar, permissões — conforme implementado).

**Backend:** Endpoints de user-admin (ex.: `GET/POST/PUT/DELETE /api/user-admins` ou similar no core); verificar no client se já existem chamadas.

---

## 11. Notificações (`/notifications`)

**Arquivo:** `pages/Notifications.tsx`

**O que faz:** Tela de notificações (conteúdo conforme implementação).

**Backend:** Se houver API de notificações, será algo como `GET /api/notifications` (verificar no core).

---

## Cliente API (src/api/client.ts)

- Base: `const BASE = '/api'`.
- Autenticação: header `Authorization: Bearer <token>` com token em `localStorage` (chave `automation-app-v3-user`).
- Respostas não-ok: `handleResponse` faz `throw new Error(body)`; as telas tratam em `.catch()` e exibem mensagem ao usuário.

---

## Resumo por backend

| Backend (controller)   | Endpoints usados pelo front |
|------------------------|-----------------------------|
| AuthController         | POST /auth/login, GET/PUT /auth/me, PUT /auth/me/password |
| FlowStepController     | GET /flow-steps, GET /flow-steps/:id, POST/PUT/DELETE /flow-steps |
| FlowStepImageController| GET /flow-step-images, GET /flow-step-images/by-step/:id, GET /flow-step-images/:id/file, POST /flow-step-images, POST /flow-step-images/upload, PUT/DELETE /flow-step-images/:id |
| SalesOrderController   | GET/POST /sales-orders, GET/PUT/DELETE /sales-orders/:id |
| CustomerController     | GET/POST /customers |
| RangeServer (ou similar)| GET /range-servers |
| GameAccountController  | GET/POST/PUT/DELETE /game-accounts |
| GameDetailsAccount     | GET/POST/PUT /game-details-accounts |

Documento gerado para servir de referência ao time e na evolução do produto.
