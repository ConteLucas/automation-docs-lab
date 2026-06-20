# Estrutura do projeto e boas práticas

## Estrutura de pastas (`src/`)

```
src/
├── api/           # Cliente HTTP (client.ts) – chamadas ao backend
├── components/    # Componentes reutilizáveis (AppShell, EditOrderModal, FlowDiagramCanvas, PriorityCircle)
├── context/       # React Context (AuthContext, ThemeContext)
├── hooks/         # Custom hooks (usar para lógica reutilizável)
├── pages/         # Páginas por rota
│   ├── FlowManagement/   # Páginas grandes: pasta com index.tsx + constantes, tipos, utils (e opcionalmente components/)
│   │   ├── index.tsx
│   │   ├── constants.ts
│   │   ├── types.ts
│   │   ├── utils.ts
│   │   └── README.md
│   ├── Login.tsx
│   ├── Customers.tsx
│   └── ...
├── types/         # Tipos TypeScript alinhados à API (api.ts)
├── App.tsx
├── main.tsx
└── index.css      # Tailwind + variáveis CSS de tema
```

- **api**: um único módulo `client.ts` com objeto `api` e funções por domínio (auth, customers, flows, tasks, etc.).
- **components**: apenas componentes usados em mais de uma página ou com lógica de apresentação relevante.
- **pages**: um componente por rota. Páginas muito grandes (ex.: FlowManagement, 2000+ linhas) ficam numa **pasta** com o nome da página: `FlowManagement/index.tsx` como entrada, mais `constants.ts`, `types.ts`, `utils.ts` e, se necessário, `components/` locais (Header, Cards, Modals, etc.). Assim a manutenção fica por partes em vez de um único ficheiro gigante.
- **context**: estado global (auth, tema); manter mínimo.
- **hooks**: para lógica reutilizável (ex.: useBreakpoint, useFlowDiagram) quando for necessário; evitar duplicar lógica entre páginas.

## Dependências

- **React 18** + **react-router-dom**: UI e rotas.
- **@xyflow/react** + **dagre**: diagramas (Flow Management, imagens por step).
- **lucide-react**: ícones (um único pacote de ícones).
- **Sem framer-motion**: removido por não uso; adicionar só se houver necessidade real de animações.

Manter o número de dependências baixo; avaliar antes de adicionar novas.

## Boas práticas adotadas

1. **Código não usado**: remover arquivos backup (`.backup.tsx`, etc.), componentes e hooks não referenciados.
2. **Tipos**: tipos da API em `types/api.ts`; usar em `api/client.ts` e nas páginas.
3. **Tema**: variáveis CSS (`--app-bg`, `--app-surface`, `--app-border`, `--app-text`, `--app-muted`, `--app-accent`) em `index.css`; usar em vez de cores fixas para dark/light.
4. **Rotas protegidas**: `ProtectedRoute` em App.tsx envolve páginas que exigem login; redireciona para `/login` com `state.from` para voltar após login.
5. **API**: token em `localStorage`; callback `setOnUnauthorized` para logout em 401; não expor dados sensíveis no cliente.
6. **Nomenclatura**: pastas em minúsculas; componentes em PascalCase; ficheiros de página com nome da rota/funcionalidade (ex.: FlowManagement, Customers, Tasks).

## Limpeza realizada (referência)

- Removida dependência **framer-motion** (não utilizada).
- Removidos arquivos backup: `FlowManagement.backup.tsx`, `FlowManagement.backup-dnd.tsx`, `FlowManagement.before-3-level.tsx`, `FlowStepImages.backup-dnd.tsx`.
- Removidos código e ficheiros não usados: `AppLayout.tsx`, `Admin.tsx`, `useBreakpoint.ts`, `useFlowDiagram.ts`.
