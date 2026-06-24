# MarketLAB

**MarketLAB** é o marketplace de contas de jogos: catálogo público, compra/venda com carteira integrada, anúncios e (por jogo) vitrine de prestadores de serviço.

| | |
|---|---|
| **URL principal** | `/marketplace` |
| **Login / cadastro** | `/marketplace/login` |
| **Admin (via Suite)** | `/admin/markt` |
| **Marca visual** | Verde `#a4e768` / `#B8FF00` · wordmark `Market[LAB]` |
| **Código** | `automation-web-lab/src/pages/marktlab/` |

> Na URL e no admin usamos o slug **`markt`** (`/admin/markt`) para não colidir com as rotas públicas `/marketplace/*`.

---

## O que é

MarketLAB é a **vitrine comercial** da suite: visitantes exploram jogos e anúncios; compradores criam conta e usam carteira; vendedores publicam contas; gestores moderam por jogo. Parte da experiência de **ProviderLAB** aparece embutida em `/marketplace/:gameSlug/servicos`.

---

## Página A vs página B (`/marketplace`)

| Estado | Hero da landing |
|--------|-----------------|
| **B — Visitante** | Layout centralizado + barra de stats (contagem da API ou fallback “320+”) |
| **A — Logado** | Hero assimétrico com mascote + CTA “Explorar contas” |

Restante da homepage (categorias, destaques, como funciona) é compartilhado; dados vêm da API de catálogo quando disponível.

---

## O que o site oferece hoje

### Páginas públicas (visitante)

| Rota | Conteúdo |
|------|----------|
| `/marketplace` | Homepage / landing |
| `/marketplace/catalogo` | Catálogo geral |
| `/marketplace/:gameSlug` | Página do jogo + listagens |
| `/marketplace/conta/:id` | Detalhe do anúncio |
| `/marketplace/planos` | Planos |
| `/marketplace/contato` | Contato |
| `/marketplace/como-funciona` | Explicação do fluxo |
| `/marketplace/destaque` | Destaques |
| `/marketplace/jogo` | Hub de jogos |
| `/marketplace/cadastro` | Escolha de persona (comprador, etc.) |
| `/marketplace/:gameSlug/servicos` | Prestadores do jogo (ProviderLAB) |

Layout: `MarketplaceLayout` + tema/carrinho (`MarketplaceThemeProvider`, `MarketplaceCartProvider`). WhatsApp flutuante e chat quando logado.

### Área logada

| Rota | Conteúdo |
|------|----------|
| `/marketplace/anunciar` | Painel do vendedor (meus anúncios) |
| `/marketplace/anunciar/conta/:id` | Editor de anúncio |
| `/marketplace/wallet` | Carteira (saldo, extrato, custódia) |
| `/marketplace/minha-conta` | Perfil, confirmação de e-mail |

**Login:** `/marketplace/login` com aba **Cadastrar** (persona comprador → role `CUSTOMER`). OAuth no cadastro quando configurado.

Qualquer usuário autenticado pode **gerir os próprios anúncios** (`canManageMarketplaceListings`).

### Admin MarketLAB (`/admin/markt`)

| Rota | Conteúdo | Permissão |
|------|----------|-----------|
| `/admin/markt` | Config global: CRUD de jogos, menu do site, ativar/desativar | DEV/ADM |
| `/admin/markt/jogo` | Editor visual da página de um jogo | DEV/ADM |
| `/admin/markt/:gameSlug` | Painel por jogo: publicados, prestadores, categorias | DEV/ADM/MANAGER |
| `/admin/markt/conta/:id` | Redirect → editor de anúncio | autenticado |

**MANAGER** em `/admin/markt` (home global) é redirecionado para `/marketplace/anunciar` — modera por jogo, não configura o site inteiro.

Rotas legadas `/marketplace/admin/*` redirecionam para `/admin/markt/*`.

---

## Público-alvo

| Role | Experiência |
|------|-------------|
| Visitante | Navegação, detalhe de conta, cadastro |
| CUSTOMER | Compra, wallet, minha conta |
| SELLER | Anunciar + painel Macro se tiver acesso |
| SERVICE_PROVIDER | Serviços via página do jogo |
| DEV/ADM | Admin site + todos os jogos |
| MANAGER | Admin por jogo (`/admin/markt/:slug`) |

---

## Integração com outros módulos

- **ProviderLAB** — listagem e cadastro de prestadores em `/marketplace/:gameSlug/servicos`; moderação em `/admin/provider` e por jogo no admin markt.
- **MacroLAB** — `MacroGameDashboard` no admin por jogo; equipe operacional pode ser seller.
- **SuiteLAB** — hub `/menu`, admin `/admin`, chat e wallet compartilhados.
- **Carteira** — API `wallet` no core; escrow e custódia descritos na UI de wallet.

---

## O que ainda não é (limitações atuais)

- Checkout/checkout NuPay e fluxo completo de escrow dependem de backend e config de produção.
- Nem todos os jogos do config local têm dados reais de listagens na API.
- Admin markt ainda usa parte do layout escuro legado do marketplace (polish visual em evolução).

---

## Arquivos-chave

```
src/pages/marktlab/features/MarketplaceLanding.tsx
src/pages/marktlab/configs/MarketplaceLayout.tsx
src/pages/marktlab/admin/MarketplaceAdmin.tsx
src/pages/macrolab/admin/MacroGameDashboard.tsx   # painel por jogo no admin markt
src/config/suiteAdminPaths.ts                     # ADMIN_MARKT_*
```
