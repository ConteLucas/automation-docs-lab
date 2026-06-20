# Segurança – automation-app-web

## O que já está implementado

- **Token em localStorage**: chave `automation-app-v3-user` (migra automaticamente de `automation-app-v2-user`); sessão persiste até logout ou limpeza do cache.
- **Logout automático em 401**: qualquer resposta 401 da API dispara logout e limpeza do token (via `setOnUnauthorized` no client).
- **Redirect seguro no login**: o parâmetro `from` é validado para evitar open redirect (apenas caminhos internos que começam por `/`).
- **Meta de segurança no HTML**: `Referrer-Policy: strict-origin-when-cross-origin`, `X-Content-Type-Options: nosniff`.
- **Sem uso de `dangerouslySetInnerHTML`** nem `eval` no código da aplicação.

## Headers HTTP recomendados em produção

Configure o servidor (nginx, Caddy, etc.) para enviar estes headers nas respostas da aplicação:

```nginx
# Exemplo nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
# Content-Security-Policy: ajustar conforme fontes permitidas (fonts, API, etc.)
# add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data:; connect-src 'self';" always;
```

- **X-Frame-Options: SAMEORIGIN** – reduz risco de clickjacking.
- **X-Content-Type-Options: nosniff** – evita MIME sniffing.
- **Referrer-Policy** – controla o que é enviado no `Referer`.
- **Permissions-Policy** – desativa APIs do browser que a app não usa.
- **Content-Security-Policy** – opcional; ao usar, adaptar às origens da app (API, fonts, etc.).

## HTTPS

Em produção, sirva a aplicação apenas por **HTTPS**. O token é enviado no header `Authorization`; em HTTP pode ser interceptado.

## Backend

- Autenticação e expiração de token são responsabilidade do backend (automation-core-ddt).
- CORS deve restringir origem aos domínios da aplicação.
- Não expor dados sensíveis em mensagens de erro (ex.: “Login ou senha inválidos” em vez de detalhes internos).
