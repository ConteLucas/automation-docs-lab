# Produção – Config e Segurança (automation-app-web)

Checklist do que é necessário para deixar o app pronto para produção em termos de **configuração** e **segurança**.

---

## 1. Configuração

### 1.1 Variáveis de ambiente

| Variável | Obrigatória | Uso |
|----------|-------------|-----|
| `VITE_CORE_TARGET` | Só em **dev** (proxy Vite) | URL do Core para o proxy `/api`. Em produção não é usada pelo frontend. |
| `VITE_ACTIVE_FLOW_GROUP` | Não | Ambiente de flow exibido (ex.: `flow_local`). Default: `flow_local`. |

- Use **`.env.example`** em `automation-web-lab` como modelo; copie para `.env.local` (dev) ou `.env.production` (build).
- **Nunca** commitar `.env`, `.env.local` ou `.env.production` com valores reais.
- Garantir que `.gitignore` inclua: `.env`, `.env.local`, `.env.*.local`, `.env.production` (ou pelo menos `.env`).

### 1.2 Build de produção

- O frontend usa **sempre** a URL relativa **`/api`** para chamadas ao backend (ver `src/api/client.ts`).
- Em produção não existe proxy Vite; o **reverse proxy** (Nginx, Caddy, etc.) deve:
  - Servir os arquivos estáticos do build (ex.: `dist/`).
  - Encaminhar **`/api`** para o serviço do automation-core (ex.: `http://core:8080`).

Exemplo Nginx (conceitual):

```nginx
server {
  listen 80;
  server_name app.example.com;
  root /var/www/automation-app-web/dist;
  index index.html;
  location / {
    try_files $uri $uri/ /index.html;
  }
  location /api {
    proxy_pass http://core:8080;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

- Build: `npm run build` → saída em `dist/`.
- Não é necessário definir `VITE_CORE_TARGET` no build de produção para o cliente; ela só afeta o proxy em dev.

---

## 2. Segurança

### Core (automation-core-ddt)

Segurança de API, secrets e worker: ver [`docs/core/SECURITY-PRODUCTION.md`](../../core/SECURITY-PRODUCTION.md).

Deploy prod: copie `.env.prod.example` → `.env.prod` na raiz do monorepo e use `SPRING_PROFILES_ACTIVE=prod`.

### 2.1 Já implementado

- **Token em memória + localStorage**: login persiste após refresh; 401 global limpa o token e redireciona (via `setOnUnauthorized`).
- **Headers no HTML** (`index.html`):
  - `X-Content-Type-Options: nosniff`
  - `Referrer-Policy: strict-origin-when-cross-origin`
- **HTTPS**: deve ser configurado no reverse proxy (certificado TLS); o app em si não trata HTTP/HTTPS.

### 2.2 Recomendações para produção

1. **HTTPS obrigatório**  
   Servir o app e a API apenas por HTTPS no reverse proxy.

2. **Content-Security-Policy (CSP)**  
   Configurar no **servidor** (recomendado) ou, se necessário, via `<meta http-equiv="Content-Security-Policy">` no `index.html`.  
   Exemplo restritivo (ajustar conforme fontes reais – fonts, analytics, etc.):

   ```
   default-src 'self'; script-src 'self'; style-src 'self' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; connect-src 'self' /api; img-src 'self' data:; frame-ancestors 'none'
   ```

3. **Token em localStorage**  
   O token JWT fica em `localStorage`; em caso de XSS pode ser lido. Mitigações:
   - Evitar qualquer inserção de HTML não sanitizado (o app usa React, o que já reduz risco).
   - Considerar no futuro **HttpOnly cookies** para o token (exige mudança no backend para enviar/aceitar cookie em vez de `Authorization: Bearer`).

4. **Variáveis sensíveis**  
   Nada de senhas ou secrets no frontend. `VITE_*` é embutido no bundle; use apenas para URLs públicas ou flags (ex.: `VITE_ACTIVE_FLOW_GROUP`).

5. **CORS**  
   Configurado no **backend** (automation-core): em produção permitir apenas a origem do frontend (ex.: `https://app.example.com`).

6. **Source maps**  
   Para não expor o código fonte em produção, no `vite.config.ts` pode-se desativar source maps em produção:

   ```ts
   build: {
     sourcemap: false,  // ou true só para erro reporting
   }
   ```

---

## 3. Checklist rápido

- [ ] `.env` / `.env.production` não commitados; `.gitignore` cobre `.env*` (exceto `.env.example`).
- [ ] Build: `npm run build` sem erros; `dist/` servido pelo reverse proxy.
- [ ] Reverse proxy encaminha `/api` para o Core e serve os estáticos do `dist/`.
- [ ] HTTPS ativo no servidor.
- [ ] CSP configurada (servidor ou meta), se desejado.
- [ ] CORS no Core restrito à origem do frontend em produção.
- [ ] (Opcional) Source maps desativados em produção no Vite.

Com isso, o app fica pronto para produção do ponto de vista de **config** e **segurança** básica.
