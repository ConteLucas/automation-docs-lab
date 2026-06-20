# Diagrama na página Flow — Documentação técnica

Este documento descreve, em detalhes técnicos, o comportamento da **vista Diagrama** na página de gestão de fluxos em:

**URL:** `http://localhost:5175/flow?flowId=2&stepId=6`  
**Ação:** Clicar no botão **"Diagrama"** (toggle entre "Diagrama" e "Lista").

---

## 1. Contexto da página

- **Rota:** `/flow` (React Router).
- **Query params:** `flowId`, `stepId` — definem o fluxo e o step em foco.
- **Componente principal:** `FlowManagement.tsx` (página única que concentra collections, steps e imagens do step).

---

## 2. Estado relevante para o Diagrama

| Estado | Tipo | Uso |
|--------|------|-----|
| `viewMode` | `'list' \| 'diagram'` | Controla se a área do step mostra **Lista** ou **Diagrama**. |
| `selectedFlowId` | `number \| null` | ID do fluxo selecionado (collection). |
| `selectedStepId` | `number \| null` | ID do step selecionado. |
| `images` | `FlowStepImage[]` | Lista **global** de todas as imagens (flow_step_image), carregada **uma vez** no mount. |
| `imagesByStep` | `Map<number, FlowStepImage[]>` | Derivado de `images`: agrupa por `flow_step_id`, ordenado por `step_img_number`. |

**Carregamento das imagens:** em `loadAll()` (useEffect no mount):

- `api.listFlowStepImages()` → resultado em `setImages(i)`.
- `imagesByStep` é calculado com `useMemo` a partir de `images`: agrupa por `flow_step_id` e ordena cada grupo por `step_img_number`.

Ou seja: **não há nova requisição** ao trocar para Diagrama; a vista usa os dados já em memória.

---

## 3. Onde o Diagrama aparece (posicionamento na UI)

- O toggle **"Diagrama" / "Lista"** só é exibido quando **há flow e step selecionados** (`selectedFlowId != null && selectedStepId != null`).
- Ao clicar em **"Diagrama"**, `viewMode` passa a `'diagram'`.
- A área que muda é a **seção do step** (Nível 3): a mesma região que, em modo Lista, mostra a tabela de imagens; em modo Diagrama mostra o layout descrito abaixo.

**Estrutura geral da página (resumida):**

1. **Nível 1:** Lista de collections (flows) em cards.
2. **Nível 2:** Lista de steps do flow selecionado em cards.
3. **Nível 3:** Conteúdo do step selecionado:
   - Se `viewMode === 'list'` → tabela de imagens (colunas: #, image_path, Ações).
   - Se `viewMode === 'diagram'` → **Diagrama** (card do step + chips das imagens).

---

## 4. O que a vista Diagrama exibe (conteúdo e layout)

Quando `viewMode === 'diagram'`:

1. **Card do step**
   - Título com nome do step e número (ex.: step number no fluxo).
   - Estilo de card (borda, padding) para destacar o step.

2. **Imagens do step**
   - Fonte: `stepImages = (imagesByStep.get(step.id) ?? []).sort((a,b) => a.stepImgNumber - b.stepImgNumber)`.
   - Cada imagem é um **chip inline** (não é preview bitmap), contendo:
     - Ícone de imagem (`ImageIcon`).
     - Texto `#stepImgNumber` (ordem da imagem no step).
     - Botão **Editar** (abre modal de edição da flow_step_image).
     - Botão **Excluir** (confirmação e chamada à API de delete).
   - Link **"Ver página de imagens"** → navega para `/flow/${stepId}/imagens` (página dedicada com tabela, diagrama com previews e drag-and-drop).
   - Botão **"Add"** → abre modal para criar nova flow_step_image (upload/caminho conforme implementação do modal).

**Importante:** Nesta vista Diagrama em **FlowManagement** **não** há:
- Preview das imagens (thumbnails/bitmap).
- Drag-and-drop para reordenar.
- Números de ordem editáveis inline.

Ou seja: é uma vista **compacta** de referências (step + lista de chips por imagem), útil para ver rapidamente quantas imagens existem e acessar edição/exclusão ou ir para a página completa de imagens.

---

## 5. Tecnologias e padrões usados

- **React** (hooks: `useState`, `useMemo`, `useCallback`, `useEffect`).
- **React Router** (`useSearchParams` para `flowId` e `stepId`).
- **UI:** Material-UI (`Card`, `CardContent`, `Chip`, `Button`, ícones como `ImageIcon`, `ListOrdered`, etc.).
- **Dados:** Estado local; imagens carregadas uma vez via `api.listFlowStepImages()` e derivadas em `imagesByStep`.
- **API:** `listFlowStepImages`, `updateFlowStepImage`, delete de flow_step_image; criação via modal (API de create flow_step_image).

---

## 6. Fluxo de interação ao clicar em "Diagrama"

1. Usuário tem `flowId` e `stepId` na URL (ex.: 2 e 6) e flow/step selecionados.
2. Clica no botão **"Diagrama"**.
3. `setViewMode('diagram')` é chamado.
4. Re-render: a condição `viewMode === 'diagram'` passa a ser verdadeira na seção Nível 3.
5. O componente renderiza:
   - O card do step atual (dados do `step` já em estado/contexto da página).
   - A lista `stepImages` vinda de `imagesByStep.get(step.id)`, ordenada por `step_img_number`.
   - Para cada item, um chip com #, Editar e Excluir; mais o link "Ver página de imagens" e o botão Add.

Nenhuma requisição HTTP nova é feita só por abrir o Diagrama; todas as imagens já estão em `images`/`imagesByStep`.

---

## 7. Relação com a página "Ver página de imagens"

- **FlowManagement, vista Diagrama:** lista compacta por step (chips, sem preview).
- **Rota `/flow/:stepId/imagens` (FlowStepImages):** página dedicada ao step com:
  - Tabela completa de imagens.
  - **Diagrama do fluxo** com **previews** das imagens e **drag-and-drop** para reordenar.
  - Modais de edição e "Alterar posição".

Ou seja: o "Diagrama" em `/flow?flowId=2&stepId=6` é uma vista resumida; o diagrama com previews e reordenação está na página de imagens do step.

---

## 8. Resumo

| Aspecto | Detalhe |
|--------|---------|
| **URL** | `/flow?flowId=2&stepId=6` |
| **Toggle** | Botão "Diagrama" define `viewMode === 'diagram'` |
| **Posição** | Seção Nível 3 (conteúdo do step selecionado) |
| **Dados** | `images` (global) → `imagesByStep` (Map por step) → `stepImages` para o step atual |
| **Conteúdo** | Card do step + chips (ícone + #ordem + Editar + Excluir) + link "Ver página de imagens" + Add |
| **Sem** | Preview de imagem, drag-and-drop, edição de ordem inline nesta vista |
| **Requisições** | Nenhuma ao alternar para Diagrama (dados já carregados em `loadAll`) |

Este documento serve como referência para modificar o diagrama (por exemplo, adicionar previews ou reordenação nesta própria vista) e como backup da descrição do comportamento atual.
