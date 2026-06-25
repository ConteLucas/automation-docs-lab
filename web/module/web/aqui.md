# Grid de posicionamento — landings dos módulos SuiteLAB

Documento de referência para **alinhamento espacial** (padding, colunas, max-width) entre `/menu`, `/marketplace`, `/providers` e `/macro`.

**Escopo:** posição e enquadramento dos elementos — **não** cores, copy, imagens ou redesign visual.

**Código-fonte dos tokens:** `automation-web-lab/src/components/labShell/labPageLayout.ts`

**Última atualização:** 2026-06-24

---

## Problema observado

O hero do **MarketLAB** (`/marketplace`) aparece com enquadramento diferente de **Menu** (`/menu`) e **ProviderLAB** (`/providers`), embora compartilhem o mesmo `LabShellLayout` (header 74px, `main.w-full`).

Exemplo de DOM no hero do marketplace:

```html
<section class="relative overflow-hidden" style="padding: 64px 0px 60px; …">
```

- A **section** não tem padding horizontal.
- O conteúdo fica dentro de `MarketplaceBrowseContainer`, com `max-width: 1024px` e `padding: clamp(28px, 7vw, 88px)`.
- Menu e Providers aplicam padding **direto na section** com `clamp(20px, 4vw, 56px)`.

**Prod vs local:** diferenças de `width`/`height` no inspetor (ex.: 1098px vs 1161px) refletem **largura da janela**, não divergência de deploy. A estrutura é a mesma; o desalinhamento é **arquitetural** (três padrões de grid coexistindo).

---

## Estado atual (por módulo)

| Módulo | Rota | Padding da section hero | Container interno | Max-width do conteúdo |
|--------|------|-------------------------|-------------------|------------------------|
| SuiteLAB | `/menu` | `clamp(40px,6vw,64px) clamp(20px,4vw,56px) clamp(36px,5vw,60px)` | `MenuSectionGridWrap` — full width | Sem cap na section; copy `max-w-[500px]` |
| ProviderLAB | `/providers` | `64px clamp(20px,4vw,56px) 60px` | Direto na section | Copy `max-w-[600px]` |
| MacroLAB | `/macro` | `64px clamp(20px,4vw,56px) 60px` | Direto na section | Copy `max-w-[600px]` |
| MarketLAB | `/marketplace` | **`64px 0 60px`** (sem lateral) | `MarketplaceBrowseContainer` | **1024px** + pad `clamp(28px,7vw,88px)` |

### Tokens específicos do Market (vitrine)

Arquivo: `automation-web-lab/src/pages/marktlab/catalog/listingDetail/listingDetailTheme.ts`

| Constante | Valor | Uso pretendido |
|-----------|-------|----------------|
| `MARKETPLACE_BROWSE_MAX_WIDTH` | `1024` | Catálogo, vitrine, listagens |
| `MARKETPLACE_BROWSE_PAD` | `clamp(28px, 7vw, 88px)` | Padding lateral da vitrine |

**Erro de uso atual:** esses tokens da **vitrine** estão aplicados também no **hero** da landing (`MarketplaceLanding.tsx`), o que estreita e desloca o bloco copy + mascote em relação aos outros módulos.

### O que já está correto no Market

`MarketplacePageChrome.tsx` usa `labPageHeroPadding()` para páginas internas (planos, contato, etc.). O **landing principal** (`MarketplaceLanding.tsx`) **não** usa esse helper.

---

## Proposta: grid único de posicionamento

### Princípio

1. **Um sistema de slots** para todos os landings (Página B — visitante).
2. **Tema por módulo** só altera cor, gradiente, texto e mascote — não a grade.
3. **Dois níveis de largura:**
   - **Hero:** largura do site (`LAB_PAGE_PAD_X`, opcional cap 1400px).
   - **Browse/vitrine:** coluna mais estreita (1024px) **abaixo do fold**, só no Market.

### Tokens canônicos

Definidos em `labPageLayout.ts`:

```ts
LAB_PAGE_PAD_X = 'clamp(20px, 4vw, 56px)'

labPageHeroPadding()   // top + laterais + bottom do hero
labPageSectionPadding() // seções abaixo do hero
```

| Token | Valor | Papel |
|-------|-------|-------|
| `LAB_PAGE_PAD_X` | `clamp(20px, 4vw, 56px)` | Margem lateral padrão da suite |
| `labPageHeroPadding()` | `clamp(40px,6vw,64px) {PAD_X} clamp(36px,5vw,60px)` | Padding da section hero |
| `labPageSectionPadding()` | `18px {PAD_X} 56px` | Seções de conteúdo |
| `LAB_CONTENT_MAX` | `1400px` (`mp-container`) | Largura máxima do site |
| `LAB_HERO_COPY_MAX` | `600px` | Coluna de texto (eyebrow, h1, CTAs) |
| `LAB_HERO_GAP` | `16px` → `24px` (`lg`) | Espaço entre copy e mascote |

### Componentes sugeridos (implementação futura)

Nomes propostos — ainda não existem como um único módulo; hoje cada landing repete markup inline.

```text
<LabHeroSection module="suite|macro|markt|provider">
  <LabHeroGrid>
    <LabHeroCopy maxWidth={600}>
      eyebrow · h1 · subtítulo · CTAs · trust badges · stats (opcional)
    </LabHeroCopy>
    <LabMascotHero module="…" align="end" />
  </LabHeroGrid>
</LabHeroSection>
```

**Regras:**

- `LabHeroSection` aplica **sempre** `labPageHeroPadding()` na `<section>`.
- **Nunca** `padding: 64px 0 60px` no hero.
- `LabHeroGrid`: `flex flex-col items-center gap-4 lg:flex-row lg:items-center` (padrão já usado em Menu/Providers/Macro).
- `LabMascotHero`: coluna direita, `align="end"`.

---

## Mapa de slots (para prompt de design / Figma)

Mesma grade em todos os módulos; variam apenas cor, copy e imagem do mascote.

```text
┌─────────────────────────────────────────────────────────────┐
│ HEADER — LabShellHeader (74px, sticky)                      │
├─────────────────────────────────────────────────────────────┤
│ SECTION HERO — padding: labPageHeroPadding()                │
│  fundo: gradiente radial por módulo (não afeta posição)     │
│  ┌──────────────────────────┬──────────────────────────┐   │
│  │ COL A — copy             │ COL B — mascote          │   │
│  │ max-width: 600px         │ align: end               │   │
│  │ · eyebrow (12px, caps)   │ LabMascotHero            │   │
│  │ · h1                     │                          │   │
│  │ · subtítulo (max ~500px) │                          │   │
│  │ · CTAs (52px height)     │                          │   │
│  │ · trust badges (wrap)    │                          │   │
│  │ · stats bar (opcional)   │                          │   │
│  └──────────────────────────┴──────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│ SECTIONS — padding: labPageSectionPadding()                 │
│  Market: pode usar MarketplaceBrowseContainer (1024) aqui   │
│  Demais módulos: full width com LAB_PAGE_PAD_X              │
└─────────────────────────────────────────────────────────────┘
```

### Slots fixos (dimensões de posição)

| Slot | Desktop | Mobile |
|------|---------|--------|
| Header height | 74px | 74px |
| Hero padding top | `clamp(40px, 6vw, 64px)` | idem |
| Hero padding lateral | `clamp(20px, 4vw, 56px)` | idem |
| Hero padding bottom | `clamp(36px, 5vw, 60px)` | idem |
| Coluna copy | `max-width: 600px`, `text-left` | `text-center`, full width |
| CTAs | `height: 52px`, gap 12px, row em `sm+` | coluna centralizada |
| Mascote | coluna direita, `lg:flex-row` | abaixo ou ao lado conforme breakpoint |
| Seção abaixo | `18px` top + `LAB_PAGE_PAD_X` + `56px` bottom | idem |

---

## Onde usar cada max-width

| Zona | Max-width | Módulos | Arquivo típico |
|------|-----------|---------|----------------|
| Hero (todos) | Full + `LAB_PAGE_PAD_X` (cap 1400 opcional) | menu, macro, markt, provider | `*Landing.tsx`, `MenuGuestView.tsx` |
| Vitrine / catálogo | **1024px** | só Market | `MarketplaceBrowseContainer`, `MarketplaceLandingSections` |
| Texto do hero | **600px** | todos | coluna copy dentro do hero |

---

## Migração mínima (MarketLAB, só posição)

Sem mudar cores, copy ou mascote:

1. **`MarketplaceLanding.tsx`**
   - Trocar `padding: '64px 0 60px'` por `labPageHeroPadding()` (ou `LabHeroSection`).
   - Remover `MarketplaceBrowseContainer` **do hero**.
   - Usar o mesmo `flex` direto na section que Provider/Macro usam.

2. **`MarketplaceLandingSections.tsx`**
   - Manter `MarketplaceBrowseContainer` **apenas** nas seções de catálogo/destaques.

3. **`listingDetailTheme.ts`**
   - `MARKETPLACE_BROWSE_PAD` alinhado a `LAB_PAGE_PAD_X` no hero, se a vitrine precisar de pad maior — só **abaixo do fold**.

4. **Demais landings**
   - Refatorar para `LabHeroSection` quando o componente existir; até lá, garantir `labPageHeroPadding()` em todas as `<section>` hero.

---

## Arquivos de referência no código

| Arquivo | Papel |
|---------|-------|
| `src/components/labShell/labPageLayout.ts` | Tokens de padding |
| `src/pages/shared/Menu/MenuGuestView.tsx` | Referência alinhada (menu) |
| `src/pages/providerlab/configs/ProviderLanding.tsx` | Referência alinhada (provider) |
| `src/pages/macrolab/configs/MacroLanding.tsx` | Referência alinhada (macro) |
| `src/pages/marktlab/catalog/MarketplaceLanding.tsx` | **Desalinhado** — hero com pad 0 lateral |
| `src/pages/marktlab/catalog/MarketplaceBrowseContainer.tsx` | Container vitrine (não usar no hero) |
| `src/pages/marktlab/configs/MarketplacePageChrome.tsx` | Hero interno já usa `labPageHeroPadding()` |
| `src/components/labShell/LabShellLayout.tsx` | Shell comum (`main.w-full`) |
| `src/components/labShell/LabShellHeader.tsx` | Header 74px |

---

## Checklist de validação visual

Comparar lado a lado em **mesma largura de viewport** (ex. 1280px e 390px):

- [ ] Eyebrow, h1 e primeiro CTA começam na **mesma distância da borda esquerda** em `/menu`, `/marketplace`, `/providers`, `/macro`.
- [ ] Mascote ocupa a **mesma coluna direita** relativa ao header.
- [ ] Não há scroll horizontal no hero.
- [ ] Seções abaixo do hero podem ter larguras diferentes (1024 no Market), mas o **hero** deve ser idêntico em grade.

---

## Relacionados

- [README.md](./README.md) — índice dos módulos web
- [markt/README.md](./markt/README.md) — MarketLAB
- [../../ESTRUTURA-E-BOAS-PRATICAS.md](../../ESTRUTURA-E-BOAS-PRATICAS.md) — pastas do frontend
- [../../VISUAL-VALIDATION-PROMPT.md](../../VISUAL-VALIDATION-PROMPT.md) — prompt de validação visual
