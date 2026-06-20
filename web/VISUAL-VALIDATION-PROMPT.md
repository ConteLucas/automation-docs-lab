# Prompt de validação visual — Automation App Web v3

Use este prompt com um revisor humano, com outro agente de IA, ou em sessão de QA visual. Ele descreve **cada rota**, **o que deve aparecer**, **para que serve no negócio**, e **critérios visuais** — com foco especial em **Flow Management** (modelo L1–L4).

---

## Prompt (copiar da linha abaixo até o fim)

```
Você é um revisor de UX/UI e QA visual do produto **Automation App Web v3** (front do mono-repo automation-learn). Sua missão: navegar o site link por link, comparar o que aparece na tela com o que está descrito abaixo, e produzir um relatório estruturado de conformidade visual, clareza de informação e gaps.

## Ambiente de teste

- **URL base (Docker):** http://localhost:5175
- **URL dev local (opcional):** http://localhost:5174 (`npm run dev` em automation-app-web)
- **Login padrão seed:** `admin` / `admin`
- **Versão esperada no header:** texto **Automation-Core-DDT v3** e título da aba **Automation v3**
- **Hard refresh:** Cmd+Shift+R (ou aba anônima) para evitar bundle antigo em cache
- **Tema:** testar modo claro e escuro (ícone sol no header)

Se algo não bate com v3, anote como **bloqueador de validação** (cache ou deploy desatualizado).

---

## Arquitetura mental do produto

O app é o **painel operacional** do **Automation Core DDT**: pedidos de venda → tasks → workers (bots Android) executam **flows** de automação no jogo. O **Flow Management** edita o catálogo de automação em 4 níveis:

| Nível | Nome na UI / API | O que é | Exemplo LOCAL |
|-------|------------------|---------|----------------|
| **L1** | Collection | Ambiente/catálogo de macros | "Guias DDT (catálogo local)" |
| **L2** | Flow (Domain Flow) | Macro FSM do bot | LOGIN, LVL_0, RM_POP_UP |
| **L3** | Step (flow_step) | Etapa dentro da macro | STEP_1 com pathFiles |
| **L4** | Image (flow_step_image) | Template PNG + ação worker | CLICK, effect GOTO:LVL_0, timeskip_ms |

**Arestas GOTO** (laranja, tracejadas nos diagramas) representam saltos entre macros L2, derivados de `effect` nas imagens (ex.: `GOTO:LVL_0`) ou da tabela `flow_transition` no Core.

---

## Chrome global (presente em todas as páginas autenticadas)

### Header superior
- Logo **A** + **Automation-Core-DDT v3**
- Campo **Search** central (placeholder "Search") — hoje **não navega**; anotar se parece funcional mas não faz nada
- Ícones: **Ajuda** (sem ação), **Tema** (alterna claro/escuro), **Notificações** (badge "1" fixo), **Sair** (modal de confirmação)

### Sidebar esquerda (ícones)
| Ícone | Rota | Label (tooltip) |
|-------|------|-----------------|
| Casa | `/` | Início |
| Grid | `/flow` | Flow Management |
| Lista | `/pedidos` | Listar Pedidos |
| Círculo | `/pedidos/novo` | Gerar Pedido |
| Usuários | `/accounts` | Game Accounts |
| User circle | `/customers` | Clientes |
| Documento | `/tasks` | Tasks |
| Engrenagem | `/settings` | Configurações |
| Shield | `/admin/users` | Admin Usuários (só ADM) |
| Smartphone | `/admin/devices` | Dispositivos (só ADM) |
| Tag (footer sidebar) | `/notifications` | Notificações |

**Visual:** item ativo com fundo destacado e cor accent; sidebar ~64px; conteúdo principal com padding confortável.

---

## Rotas — link por link

### `/login` (sem shell)
**Para que serve:** autenticação contra Core (`/api/auth/login`).

**Deve mostrar:**
- Título "Entrar" + subtítulo **Automation App Web v3**
- Campos Login e Senha
- Botão entrar; erros em caixa vermelha
- Após login, redireciona a `/` (ou rota protegida original)

**Validar visual:** formulário centrado, card com borda, legível em dark mode.

---

### `/` — Dashboard (Início)
**Para que serve:** visão executiva rápida — pedidos, progresso de tasks, atalho a flows.

**Blocos esperados:**
1. **Order Metrics** — Total Order, Traders Totals ($), Total Totals; select "Last 7/30/90 days"; barras dos últimos pedidos
2. **Active Tasks** — até 5 pedidos com barra de progresso tasks; link a `/tasks`
3. **Flow Status** — 4 cards FLOW_LOCAL / DEV / HMG / PROD; um marcado ACTIVE (cyan); link a `/flow`
4. **Recent Activity Feed** — lista estática placeholder (sucesso/erro fictícios)

**Validar visual:** grid bento responsivo; cards com borda `rounded-xl`; sem overflow quebrado em mobile.

---

### `/flow` — Flow Management ⭐ (seção crítica)

**Para que serve:** CRUD visual do catálogo de automação (collections, flows L2, steps L3, imagens L4) que o **bot** consome via Core/worker plan.

#### Layout da página (ordem vertical)
1. **FlowHeader** — título "Flow Management"
2. **FlowCardsSection** — grid de cards coloridos (collections ou steps)
3. **FlowBreadcrumbAndToggle** — breadcrumb + toggle **Cards | Diagrama do fluxo**
4. **DomainFlowTabs** — abas L2 (só se collection tem 2+ flows com steps)
5. **FlowContentArea** — tabela ou diagramas (área com scroll)

#### Header da flow
- Select **Collection** + botão **Aplicar** + **+** (nova collection)
- Search (filtra steps por key/nome)
- **Gerar card** (cria novo step L3 no flow L2 selecionado) — só com collection aplicada

#### Cards superiores (FlowCardsSection)
- **Sem collection selecionada:** cards de **collections** (TEST, PROD, LOCAL…) — cores por `flowKey` (test/prod/local); badge ORIGINAL se aplicável; contador "N Steps"; drag para reordenar; menu engrenagem (renomear, cor, ícone, posição)
- **Com collection selecionada:** cards de **steps** do flow L2 ativo; preview contagem de imagens; clique abre step

#### Breadcrumb + modo de visualização
- Breadcrumb: `Collection: … → Flow: … → Step: …` com voltar e X
- **Cards** (padrão histórico; após v3 pode estar em **Diagrama** por default): tabelas
- **Diagrama do fluxo** (React Flow): canvas interativo

#### Abas L2 (DomainFlowTabs)
- Aparecem após aplicar collection com múltiplos flows **com steps** (ex. LOCAL: LOGIN, LVL_0, RM_POP_UP)
- Aba ativa: fundo azul; **não** deve defaultar em flow L2 vazio (ex. meta LOCAL sem steps)

#### Estados da FlowContentArea

**A) Nenhuma collection aplicada**
- Cards: tabela/lista de collections OU diagrama simples de collections
- Mensagem orientando "Aplicar"

**B) Collection aplicada, sem step aberto**
- **Modo Cards:** tabela steps com colunas #, Key, **step_key**, **path_files**, Nome, Imagens, Abrir
- **Modo Diagrama:**
  - **CollectionDiagramCanvas (L1):** nós = flows L2; título "Collection L1: …"; subtítulo "Flows L2 · arestas laranja = GOTO"; botão Auto-Layout
  - Arestas **laranja tracejadas animadas** = GOTO entre macros; cinza tracejado = ordem display
  - Abaixo: **FlowDiagramCanvas (L2)** — sequência de steps do flow L2 selecionado; nós com thumbnail; drawer lateral ao clicar step

**C) Step aberto (selectedStepId)**
- **Modo Cards:** tabela de imagens com Posição, Nome, image_path, worker_action, **effect**, **timeskip**, Ações; drag reorder; link "Ver página de imagens"
- **Modo Diagrama:**
  - **StepImageDiagramCanvas (L4):** imagens em sequência; badges **effect** / timeskip no nó; arestas sequenciais "next"; arestas laranja GOTO a nós phantom "GOTO target"
  - Lista de imagens abaixo do canvas

#### Modais (FlowModals)
- Nova collection, novo step, adicionar/editar imagem
- Imagem: step_img_number, upload, image_path, name_image, coordinates, **worker_action** (CLICK/WAIT_APPEAR/IF_VISIBLE), **effect** (GOTO:LVL_0), **timeskip_ms**, width/height

#### Collection de referência para validação rica
1. Collection: **Guias DDT (catálogo local)** → Aplicar
2. Aba **LOGIN** (ou LVL_0)
3. Abrir step → ver imagens com effect `FILL_LOGIN`, `GOTO:LVL_0`, etc.
4. Diagrama L1 deve mostrar gotos entre LOGIN ↔ LVL_0 ↔ RM_POP_UP

#### Checklist visual Flow
- [ ] Header mostra v3 no app shell (não v2)
- [ ] Toggle Cards/Diagrama visível com collection aplicada
- [ ] Diagrama L1 renderiza sem canvas vazio ou erro React Flow
- [ ] Arestas GOTO legíveis (label com texto do effect)
- [ ] Colunas effect/timeskip na tabela de imagens
- [ ] Modais de imagem têm campos effect e timeskip_ms
- [ ] Breadcrumb reflete L1 → L2 → L3
- [ ] Drag-and-drop não quebra layout (opacity, handles)
- [ ] Drawer lateral no diagrama não cobre controles do React Flow
- [ ] Mobile: tabelas com scroll horizontal; cards não colapsam ilegíveis

---

### `/flow/:stepId/imagens` — Página dedicada de imagens do step
**Para que serve:** CRUD completo L4 fora do contexto embutido em `/flow`.

**URL exemplo:** `/flow/12/imagens?flowId=3`

**Deve mostrar:**
- Link voltar: Flow → Step
- Título step + contagem imagens
- **Diagrama do fluxo** simplificado (etapa → thumbnails)
- Badges effect/timeskip nos cards do diagrama
- Tabela: #, Preview, image_path, coordinates, **effect**, **timeskip**, width×height, ações
- Botão Adicionar imagem; modais com effect/timeskip

**Validar:** consistência com modais de `/flow`; preview de PNG carrega.

---

### `/pedidos` — Listar Pedidos
**Para que serve:** listar/editar/excluir pedidos de venda; gerar tasks a partir do pedido.

**Elementos:** filtros dinâmicos, sort por colunas, tabela rica (cliente, range, prioridade, status, tasks), modais editar pedido e gerar tasks, ações admin.

---

### `/pedidos/novo` — Gerar Pedido
**Para que serve:** wizard criar pedido (cliente → range servidor → tipo ACC15/ACC30 + quantidade de contas → confirmação).

**Stepper visual** com passos numerados; opcional contas novas login/senha; aviso custo reserva R$1/acesso.

---

### `/accounts` — Game Accounts
**Para que serve:** inventário de contas do jogo (login, senha, server, level, status LIVRE/EM_USO…).

**Tabela paginada**, filtros, criar/editar, export CSV, upload, revelar senha, badges de status coloridos.

---

### `/customers` — Clientes
**Para que serve:** cadastro de compradores/revendedores vinculados a pedidos.

**CRUD** com perfil COMPRADOR/REVENDEDOR, PIX, contato, paginação.

---

### `/tasks` — Tasks
**Para que serve:** fila operacional — cada task liga pedido + conta + flow + device + status.

**Filtro** por status e `?salesOrderId=` na URL; editar status; link ao pedido.

---

### `/settings` — Configurações
**Para que serve:** perfil do usuário logado, troca de senha, preferências (tema).

**Tabs verticais:** Perfil | Segurança | Preferências; medidor de força de senha.

---

### `/admin/users` — Admin Usuários (ADM)
**Para que serve:** gestão de `user_admin` e permissões (ADM, DEV, MANAGER, SELLER).

**Drawer** criar/editar; bloquear; permissões.

---

### `/admin/devices` — Dispositivos (ADM)
**Para que serve:** workers Android registrados no Core (identifier, API key, status ATIVO/INATIVO…).

**CRUD** dispositivos; filtro incluir deletados.

---

### `/notifications` — Notificações
**Placeholder:** título + "Em breve." — não esperar UI rica.

---

## Redirecionamentos (não são páginas)
- `/flow-management` → `/flow`
- `/gerar-pedido` → `/pedidos/novo`
- `/ordens` → `/pedidos`
- `/admin` → `/admin/users`
- `*` → `/` ou `/login`

---

## Critérios transversais de qualidade visual

1. **Hierarquia:** H1 página > H2 seções > labels de formulário; nada "flutuando" sem contexto
2. **Consistência:** mesmos tokens CSS (`--app-bg`, `--app-surface`, `--app-accent`); botões primários azul/accent
3. **Dark mode:** texto legível; bordas visíveis; diagramas React Flow não com fundo branco choque
4. **Feedback:** loading "Carregando…", erros vermelho, saving states nos botões
5. **Acessibilidade básica:** botões ícone com `aria-label`; modais com `role="dialog"`
6. **Responsivo:** sidebar fixa; conteúdo scroll; tabelas `overflow-x-auto`
7. **Sem widgets mortos:** anotar Search global, Ajuda, badge notificação fixo "1" como **debt UX** se confundir

---

## Gaps conhecidos (não marcar como bug se documentado)
- CRUD de `flow_transition` L1 só leitura (GET); edição de arestas via effect nas imagens
- Activity feed do dashboard é mock
- Search do header não implementado
- Notificações placeholder

---

## Formato do seu relatório final

Para cada rota visitada:
1. **URL**
2. **Conformidade** (OK / Parcial / Falha)
3. **O que funcionou visualmente**
4. **Problemas** (screenshot mental: alinhamento, overflow, texto truncado, cores, diagrama vazio)
5. **Sugestões** (opcional, prioridade P1/P2/P3)

Resumo executivo:
- Score geral /10
- Top 5 issues visuais
- Flow Management: L1/L2/L3/L4 cada um OK ou não
- Bloqueadores de release

Comece pelo login, depois sidebar em ordem, com **≥15 minutos em /flow** usando collection LOCAL e modo Diagrama.
```

---

## Uso rápido

1. Abra http://localhost:5175 com o app Docker rodando.
2. Cole o prompt acima em um agente com visão de tela ou use como checklist manual.
3. Compare o relatório com issues em GitHub/Cursor.
