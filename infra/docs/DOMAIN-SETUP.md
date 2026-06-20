# Domínio barato (lab) — Cloudflare + EC2

Guia para sair do IP (`54.225.198.82`) e usar um nome como `https://lab.seudominio.com`.

## Onde comprar (recomendado)

**Cloudflare Registrar** — [https://dash.cloudflare.com](https://dash.cloudflare.com)

| Motivo | Detalhe |
|--------|---------|
| DNS grátis | Plano Free, sem taxa mensal de hosted zone (Route 53 cobra ~US$ 0,50/mês) |
| Preço do domínio | `.com` ~US$ 10–12/ano (preço de custo, sem markup alto) |
| HTTPS depois | Let’s Encrypt na EC2 ou proxy Cloudflare (opcional) |

### Passo a passo na compra

1. Crie conta em [cloudflare.com](https://www.cloudflare.com) (grátis).
2. Menu **Domain Registration** → **Register Domains**.
3. Pesquise um nome (ex.: `automation-learn-lab.com`, `meu-ddt-lab.dev`).
4. Pague e finalize — o domínio já fica na sua conta Cloudflare.
5. **DNS** → **Records** → **Add record**:
   - **Type:** `A`
   - **Name:** `lab` (fica `lab.seudominio.com`) — ou `@` para raiz
   - **IPv4:** `54.225.198.82` (Elastic IP da EC2)
   - **Proxy status:** **DNS only** (nuvem **cinza**) — importante para Certbot depois
   - **TTL:** Auto
6. Aguarde propagação (5–30 min, às vezes até 1 h).

### Alternativas de compra

| Registrar | Prós | Contras |
|-----------|------|---------|
| **Cloudflare** | DNS grátis integrado | Menos TLDs que Namecheap |
| **Namecheap** | Barato, muitos TLDs | DNS grátis limitado; aponte nameservers para Cloudflare |
| **Registro.br** | `.com.br` | Só domínios BR; aponte DNS para Cloudflare |

Se comprar fora da Cloudflare: em **DNS** do registrar, troque nameservers para os que a Cloudflare indicar (grátis).

## Depois de comprar — aplicar na EC2

Do Mac, na pasta `automation-infra-lab/scripts`:

```bash
# Substitua pelo FQDN real (com ou sem subdomínio)
./setup-domain.sh lab.seudominio.com 54.225.198.82 ~/.ssh/automation-learn-lab.pem
```

O script:

- Atualiza `APP_ALLOWED_ORIGINS` no `.env.prod` da EC2
- Reinicia o Core (CORS/login)
- Testa se o DNS já aponta para o IP

Abra: `http://lab.seudominio.com/login`

## HTTPS (opcional, grátis)

Com DNS em **DNS only** (nuvem cinza):

```bash
./setup-domain.sh lab.seudominio.com 54.225.198.82 ~/.ssh/automation-learn-lab.pem --https
```

Usa Let’s Encrypt (Certbot) na EC2. Porta 443 já está aberta no security group.

## O que informar ao time / ao agente

Após comprar, envie:

1. **FQDN completo** — ex.: `lab.automation-learn-lab.com`
2. Confirmação de que o registro **A** aponta para `54.225.198.82`

## Terraform (novos ambientes)

Em `terraform/terraform.tfvars`:

```hcl
app_domain = "lab.seudominio.com"
```

Novas EC2 já nascem com `APP_ALLOWED_ORIGINS` correto. **EC2 existente:** use `setup-domain.sh` (evita recriar a instância).
