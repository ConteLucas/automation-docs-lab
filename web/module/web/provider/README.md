# ProviderLAB

**ProviderLAB** é a vitrine e o onboarding de **prestadores de serviço** no ecossistema gamer: boosters, coaches, farmers e similares — com moderação centralizada pela equipe.

| | |
|---|---|
| **URL principal** | `/providers` |
| **Login / cadastro** | `/providers/login` |
| **Admin (via Suite)** | `/admin/provider` |
| **Marca visual** | Laranja `#ffb24d` / `#FF9D33` · wordmark `Provider[LAB]` |
| **Código** | `automation-web-lab/src/pages/providerlab/` |

---

## O que é

ProviderLAB **não é um painel operacional completo** hoje. É principalmente:

1. **Landing de marketing** em `/providers` (descoberta, categorias, benefícios).
2. **Fluxo de cadastro** de prestador (`SERVICE_PROVIDER`) via login/cadastro.
3. **Operação real** no **MarketLAB** — listagem, contratação e perfil público ficam em `/marketplace/:gameSlug/servicos`.
4. **Moderação** em `/admin/provider` (aprovar, banir, destacar).

O prestador ativo trabalha no contexto do jogo no marketplace; a landing Provider conecta marca e conversão.

---

## O que o site oferece hoje

### Landing pública (`/providers`)

- Hero com busca local nos prestadores em destaque.
- Cards de providers **featured** (API `useFeaturedProviders`).
- Seções: categorias de serviço (leveling, coaching, farm, PvP, missões, build).
- Benefícios para cliente vs prestador.
- Planos e “como funciona”.
- Stats dinâmicos quando há dados (quantidade, jobs, rating médio).
- Link para lista completa → ex.: `/marketplace/ddtank-origin/servicos`.

### Comportamento por tipo de usuário

| Estado | UI |
|--------|-----|
| Visitante | “Entrar” + “Ser Provider” → cadastro |
| `CUSTOMER` / `SERVICE_PROVIDER` (marketplace) | CTA “Anunciar serviços” → marketplace com `?cadastro=1` |
| `SERVICE_PROVIDER` logado | Banner de status no topo |
| Qualquer logado | `LabCrossNavLink` de volta ao MarketLAB |
| DEV/ADM | Link para `/admin/provider` na landing |

### Login e cadastro

| Rota | Função |
|------|--------|
| `/providers/login` | Login + cadastro inline (`registerFormId: 'provider-service'`) |
| `/providers/cadastro` | Redirect legado → `/providers/login?tab=register` |

Novo prestador recebe role **`SERVICE_PROVIDER`**. OAuth disponível no cadastro se configurado.

### Admin ProviderLAB (`/admin/provider`)

Painel `ProvidersAdmin` (DEV/ADM):

| Aba | Conteúdo |
|-----|----------|
| Pendentes | Perfis aguardando aprovação |
| Ativos | Prestadores publicados |
| Banidos | Contas suspensas |

**Ações:** aprovar, banir, excluir, alternar **destaque** (`featured`).

API: `listServiceProvidersAdmin`, `patchServiceProvider`, `deleteServiceProvider`.

Rota legada `/providers/admin` → `/admin/provider`.

---

## Público-alvo

| Perfil | Jornada |
|--------|---------|
| Gamer visitante | Conhecer o programa em `/providers` |
| Futuro prestador | Cadastro → aprovação admin → perfil no marketplace |
| Comprador | Contrata via `/marketplace/.../servicos` |
| DEV/ADM | Moderação em `/admin/provider` |

---

## Integração com outros módulos

```text
/providers (marca + cadastro)
    ↓ cadastro aprovado
/marketplace/:gameSlug/servicos (catálogo e perfil público)
    ↑ moderação
/admin/provider (SuiteLAB)
```

- Destaque no admin alimenta carrossel da landing Provider e ranking no marketplace.
- Cadastro pode iniciar no MarketLAB (`?cadastro=1`) se o usuário já for comprador.
- Suite: `/menu`, `/admin`, botão ← Suite, auth compartilhada.

---

## O que ainda não é (limitações atuais)

- Não há painel `/providers/dashboard` com pedidos, chat dedicado ou métricas do prestador — isso está no marketplace ou ainda não existe.
- A landing depende de jogo padrão hardcoded em alguns links (ex.: `ddtank-origin`).
- Pagamentos e escrow de serviços seguem o mesmo estágio de maturidade do MarketLAB.

---

## Arquivos-chave

```
src/pages/providerlab/ProvidersLanding.tsx
src/pages/providerlab/ProvidersLogin.tsx
src/pages/providerlab/ProvidersAdmin.tsx
src/pages/marktlab/features/MarketplaceGameServices.tsx
src/pages/suiteAdmin/SuiteAdminModulePages.tsx   # SuiteAdminProviderHome
```
