# Deploy no AWS lab (desenvolvimento)

Guia rápido: **depois do `git push`, como subir as mudanças para a EC2.**

## O essencial

`git push` **não** atualiza a AWS sozinho. Você precisa rodar o script de deploy no Mac (ou configurar GitHub Actions — ver [GITHUB-DEPLOY.md](./GITHUB-DEPLOY.md)).

```text
git push  →  deploy-service.sh <serviço>  →  testar no navegador
```

## Dados do ambiente

| Item | Valor |
|------|-------|
| IP da EC2 | `54.225.198.82` |
| Domínio | `http://automation-device-lab.com` |
| Chave SSH | `~/.ssh/automation-learn-lab.pem` |
| Pasta dos scripts | `automation-configs-lab/infra-lab/scripts/` |

Use **`http://`** (HTTPS ainda não está configurado).

## Fluxo do dia a dia

```bash
# 1. Commit e push no repo que você alterou
cd automation-web-lab   # ou core, vision, infra
git add .
git commit -m "sua mensagem"
git push

# 2. Deploy só do serviço alterado
cd ../automation-configs-lab
./infra-lab/scripts/deploy-service.sh web 54.225.198.82 ~/.ssh/automation-learn-lab.pem
```

## Qual comando usar?

| Você alterou… | Comando | Tempo aprox. |
|---------------|---------|--------------|
| `automation-web-lab` (frontend) | `./infra-lab/scripts/deploy-service.sh web 54.225.198.82 ~/.ssh/automation-learn-lab.pem` | ~20–60 s |
| `automation-core-lab` (API Java) | `./infra-lab/scripts/deploy-service.sh core 54.225.198.82 ~/.ssh/automation-learn-lab.pem` | ~2–5 min (Maven no Mac) |
| `automation-vision-lab` (OCR) | `./infra-lab/scripts/deploy-service.sh vision 54.225.198.82 ~/.ssh/automation-learn-lab.pem` | ~2–5 min |
| `automation-infra-lab` (compose, scripts) | `./infra-lab/scripts/deploy-service.sh infra 54.225.198.82 ~/.ssh/automation-learn-lab.pem` | ~10 s |
| Só usuários / login no banco | `./core-lab/scripts/seed-ec2-users.sh 54.225.198.82 ~/.ssh/automation-learn-lab.pem` | ~30 s |
| Zerar DB lab + Hibernate + seed flows | `./db-lab/scripts/reset-prod-lab-db.sh 54.225.198.82 ~/.ssh/automation-learn-lab.pem` | ~3 min |
| Só catálogos flow (API) | `./db-lab/scripts/seed-ec2-flows.sh automation-device-lab.com` | ~1 min |

**Evite** `deploy-to-ec2.sh` ou `deploy-service.sh all` no dia a dia — sobe tudo e o **core** demora muito.

## Exemplos

### Só frontend

```bash
cd automation-web-lab && git push
cd ../automation-configs-lab
./infra-lab/scripts/deploy-service.sh web 54.225.198.82 ~/.ssh/automation-learn-lab.pem
```

### Web + API (nessa ordem)

```bash
./infra-lab/scripts/deploy-service.sh core 54.225.198.82 ~/.ssh/automation-learn-lab.pem
./infra-lab/scripts/deploy-service.sh web 54.225.198.82 ~/.ssh/automation-learn-lab.pem
```

### Primeira vez ou máquina zerada

```bash
./infra-lab/scripts/deploy-to-ec2.sh 54.225.198.82 ~/.ssh/automation-learn-lab.pem
```

## O que o script faz

1. Copia o código do Mac → `/opt/automation-learn/src/<repo>/` na EC2
2. **Web:** roda `npm run build` no Mac (a EC2 não aguenta o build do Vite)
3. **Core:** roda `mvn package` no Mac e envia `deploy/app.jar` (a EC2 só monta imagem JRE — segundos)
4. **Vision:** faz `docker compose build` na EC2
5. Reinicia só o container afetado (`core`, `app-web` ou `vision`)

## Testar depois do deploy

- `http://automation-device-lab.com/login`
- ou `http://54.225.198.82/login`

Login de teste no lab: `dev` (senha em `automation-configs-lab/infra-lab/scripts/lib/ec2-lab-auth.sh`)

Imagens de templates (local vs S3): [env-images-s3.md](./env-images-s3.md)

## Outros scripts (uso pontual)

| Situação | Script |
|----------|--------|
| Configurar domínio / CORS | `./infra-lab/scripts/setup-domain.sh automation-device-lab.com 54.225.198.82 ~/.ssh/automation-learn-lab.pem` |
| Login não funciona | `./core-lab/scripts/seed-ec2-users.sh 54.225.198.82 ~/.ssh/automation-learn-lab.pem` |
| Só subir Postgres | `./infra-lab/scripts/deploy-service.sh postgres 54.225.198.82 ~/.ssh/automation-learn-lab.pem` |

## Deploy automático (opcional)

Para o deploy rodar sozinho após cada `git push`, configure GitHub Actions — passo a passo em [GITHUB-DEPLOY.md](./GITHUB-DEPLOY.md).

## Layout esperado no Mac

Os repos `*-lab` precisam estar lado a lado:

```text
automation-learn/
  automation-configs-lab/infra-lab/scripts/   ← scripts de deploy ficam aqui
  automation-infra-lab/
  automation-core-lab/
  automation-web-lab/
  automation-vision-lab/
```

Se estiver em outro caminho:

```bash
MONOREPO_ROOT=/caminho/automation-learn ../automation-configs-lab/infra-lab/scripts/deploy-service.sh web 54.225.198.82 ~/.ssh/automation-learn-lab.pem
```
