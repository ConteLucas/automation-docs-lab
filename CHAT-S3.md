# Chat unificado — MarketLAB · ProviderLAB · MacroLAB

Histórico de conversas em arquivos de texto no storage (S3 em produção, disco local em dev).  
Autenticação via **JWT Bearer** — todas as rotas de chat exigem login.

---

## Visão geral

| Canal | Produto | Quem conversa com quem | `contextId` |
|-------|---------|------------------------|-------------|
| `marketplace` | MarketLAB | Comprador ↔ vendedor do anúncio | ID da `game_account` (anúncio) |
| `provider` | ProviderLAB | Cliente ↔ dono do anúncio de serviço | ID em `ads_service_provider` |
| `macro-support` | MacroLAB | Operador ↔ suporte (`user_id=0`) | `0` = conversa do usuário logado |

A plataforma **não intermedia pagamentos** — o chat serve para negociar preço, prazo e forma de pagamento.

---

## API REST

Base: `/api/lab-chat` (autenticado).

### Inbox do usuário

```http
GET /api/lab-chat/threads
Authorization: Bearer <token>
```

Retorna conversas recentes (até 100), atualizadas a cada envio.

### Listar mensagens

```http
GET /api/lab-chat/{channel}/{contextId}/messages?peerUserId=
```

- **Comprador** (marketplace/provider): omite `peerUserId` — o backend resolve o vendedor/prestador.
- **Vendedor/prestador**: **obrigatório** `peerUserId` = ID do cliente.
- **Macro suporte**: `contextId=0` usa o usuário da sessão.
- **DEV/ADM**: podem abrir qualquer thread (`isGlobalViewer`).

### Enviar mensagem

```http
POST /api/lab-chat/{channel}/{contextId}/messages?peerUserId=
Content-Type: application/json

{ "message": "texto até 4000 caracteres" }
```

### Compatibilidade legada (marketplace)

```http
GET|POST /api/marketplace/listings/{listingId}/chat
```

Delega para o mesmo serviço (`LabChatService`).

---

## Layout no S3 / storage local

Prefixo S3 (produção):

```text
{appRoot}/{deployEnv}/marketlab/chat/
```

Exemplo:

```text
automation-device-lab/PROD/marketlab/chat/
```

### Marketplace (por anúncio, thread simétrica, um arquivo por dia UTC)

```text
marketplace/listing/{listingId}/thread_{userIdMenor}_{userIdMaior}/2026-06-21.txt
```

**Legado** (ainda lido na carga):

```text
anuncio/{listingId}/thread_{userIdMenor}_{userIdMaior}.txt
```

### Provider

```text
provider/service/{providerId}/thread_{userIdMenor}_{userIdMaior}/2026-06-21.txt
```

### Macro — suporte (um arquivo por dia por usuário)

```text
macro/support/user_{userId}/2026-06-21.txt
```

Mensagens do suporte usam `userId=0` e login `suporte`.

### Inbox (índice JSON por usuário)

```text
inbox/user_{userId}.json
```

Array de `{ channel, contextId, peerUserId, peerLogin, label, lastAt, lastPreview }`.

---

## Formato de linha (transcript)

Uma linha por mensagem, append-only:

```text
[2026-06-21T14:32:10.123Z] 42|comprador: Olá, ainda disponível?
[2026-06-21T14:33:01.456Z] 7|vendedor: Sim, podemos negociar.
```

Regex: `^\[(.+?)]\s+(\d+)\|([^:]+):\s*(.*)$`

O chat **carrega o repositório inteiro da thread**: lista todos os `.txt` do diretório (ordenados) + arquivo legado se existir.

---

## Autenticação e token

1. Login em `POST /api/auth/login` → recebe `token` + `tokenExpiresAt`.
2. Frontend guarda em `localStorage` e envia `Authorization: Bearer <token>` em cada request de chat.
3. Token expirado → `401`; o `AuthContext` faz logout.
4. Rotas de chat **não são públicas** (diferente do catálogo `/api/marketplace/catalog`).

OAuth (Google/Discord/Facebook) também gera o mesmo JWT — fluxo em `/auth/oauth/callback`.

---

## Frontend

| Componente | Uso |
|------------|-----|
| `components/chat/LabChatPanel.tsx` | Modal reutilizável |
| `MarketplaceListingChat.tsx` | Wrapper marketplace |
| `ProviderFeaturedCard.tsx` | Botão "Falar com provider" |
| `MacroLayout.tsx` | Ícone de suporte no header |

Cliente API: `listLabChatMessages`, `sendLabChatMessage`, `listLabChatThreads`.

---

## Classes backend (referência)

| Classe | Responsabilidade |
|--------|------------------|
| `LabChatService` | Regras de acesso + orquestração |
| `ChatTranscriptRepository` | Leitura/escrita de `.txt` diários |
| `LabChatPathUtil` | Paths e parsing de linhas |
| `LabChatController` | REST `/api/lab-chat` |
| `MarketplaceChatService` | Adapter legado |

Bean storage: `@Qualifier("marketlabChat")` → `S3ImageStorageAdapter` ou `LocalImageStorageAdapter`.

---

## Deploy e IAM

O prefixo IAM de produção deve incluir:

```text
automation-device-lab/PROD/marketlab/chat/*
```

(ou o `deployEnv` configurado em `APP_STORAGE_S3_DEPLOY_ENV`).

Após alterações no Core:

```bash
cd automation-configs-lab
./infra-lab/scripts/deploy-service.sh core <host> <key.pem>
```

---

## Limitações atuais (v1)

- Sem WebSocket — recarrega ao abrir o modal (polling manual possível depois).
- Append read-modify-write por dia — concorrência alta no mesmo segundo pode perder linha (aceitável no lab).
- Suporte macro: inbox do `user_id=0` não implementado — DEV vê threads via `peerUserId` / futuro painel admin.
- Provider sem página de detalhe — chat abre nos cards em destaque.

## Próximos passos sugeridos

1. Painel vendedor/prestador com lista de threads (`GET /threads`) e `peerUserId`.
2. Notificações push ao receber mensagem (`NotificationService`).
3. Polling a cada 5s com modal aberto.
4. Painel admin de suporte macro (listar `macro/support/user_*`).
