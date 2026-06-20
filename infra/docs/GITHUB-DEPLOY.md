# Deploy multi-repo (GitHub Actions → EC2)

Repos **separados** no GitHub. Cada push em `main` deploya **só o serviço** correspondente.

## Layout na EC2

```
/opt/automation-learn/
  .env.prod                          # secrets (criado pelo Terraform user-data)
  src/
    automation-infra-lab/            # compose + scripts
    automation-core-lab/             # repo Core
    automation-web-lab/              # repo Web
    automation-vision-lab/           # repo Vision
```

## Repositórios GitHub (4)

| Repo | Deploy | Container |
|------|--------|-----------|
| `automation-infra-lab` | compose, scripts | — |
| `automation-core-lab` | API Spring | `core` |
| `automation-web-lab` | frontend | `app-web` |
| `automation-vision-lab` | OCR/visão | `vision` |

`postgres` sobe na 1ª vez via script local ou workflow manual.

## 1. Subir `automation-infra-lab` primeiro

Este repo contém o workflow **reutilizável** que os outros chamam.

```bash
cd automation-infra-lab
git init
git remote add origin https://github.com/SEU_ORG/automation-infra-lab.git
git add .
git commit -m "Initial infra"
git push -u origin main
```

Adicione workflow de infra (opcional):

```bash
mkdir -p .github/workflows
cp templates/github-workflows/automation-infra-lab-deploy.yml .github/workflows/deploy-ec2.yml
git add .github/workflows/deploy-ec2.yml
git commit -m "ci: deploy infra to EC2"
git push
```

## 2. Secrets (em **cada** repo ou Organization secrets)

| Secret | Valor |
|--------|--------|
| `EC2_HOST` | `54.225.198.82` |
| `EC2_SSH_KEY` | conteúdo do `.pem` |
| `EC2_USER` | `ec2-user` (opcional) |

**Organization secrets** (recomendado): um lugar, todos os repos usam.

## 3. Workflow em cada app repo

Copie o template e troque `YOUR_ORG`:

```bash
# automation-core-lab
mkdir -p .github/workflows
cp ../automation-infra-lab/templates/github-workflows/automation-core-lab-deploy.yml \
  .github/workflows/deploy-ec2.yml
# Edite YOUR_ORG → seu usuario/org GitHub
```

Templates em `templates/github-workflows/`:

- `automation-core-lab-deploy.yml`
- `automation-web-lab-deploy.yml`
- `automation-vision-lab-deploy.yml`
- `automation-infra-lab-deploy.yml`

Exemplo no **core** (chama workflow reutilizável do infra):

```yaml
jobs:
  deploy:
    uses: SEU_ORG/automation-infra-lab/.github/workflows/deploy-ec2-reusable.yml@main
    secrets: inherit
    with:
      remote_subdir: automation-core-lab
      compose_service: core
      health_path: /api/health
```

## 4. 1ª deploy (manual, antes da CI)

```bash
cd automation-configs-lab
./infra-lab/scripts/deploy-service.sh infra 54.225.198.82 ~/.ssh/automation-learn-lab.pem
./infra-lab/scripts/deploy-service.sh postgres 54.225.198.82 ~/.ssh/automation-learn-lab.pem
./infra-lab/scripts/deploy-service.sh core 54.225.198.82 ~/.ssh/automation-learn-lab.pem
./infra-lab/scripts/deploy-service.sh vision 54.225.198.82 ~/.ssh/automation-learn-lab.pem
./infra-lab/scripts/deploy-service.sh web 54.225.198.82 ~/.ssh/automation-learn-lab.pem

# ou tudo de uma vez (repos lado a lado no Mac):
./infra-lab/scripts/deploy-to-ec2.sh 54.225.198.82 ~/.ssh/automation-learn-lab.pem
```

## 5. Fluxo depois

1. Push em `automation-core-lab` → só rebuild `core`
2. Push em `automation-web-lab` → npm build + rebuild `app-web`
3. Push em `automation-vision-lab` → só rebuild `vision`
4. Push em `automation-infra-lab` (compose) → atualiza compose na EC2

## Git em cada repo (sem monorepo)

```bash
cd automation-core-lab
git init
git remote add origin https://github.com/SEU_ORG/automation-core-lab.git
git add .
git commit -m "Initial commit"
git push -u origin main
```

Repita para web, vision, infra.

## Troubleshooting

| Problema | Solução |
|----------|---------|
| `Compose nao encontrado` | Rode `deploy-service.sh infra` primeiro |
| `automation-core is unhealthy` | Postgres vazio: compose usa `ddl-auto: update` no lab; redeploy `infra` + `core` |
| `rsync: command not found` | Scripts usam tar+ssh (atualize `automation-infra-lab`) |
| `Permission denied` em `/opt/automation-learn/src` | Deploy atual faz `chown ec2-user` antes do sync |
| Web build killed (OOM) | `deploy-service.sh web` builda no Mac antes do sync |
| Reusable workflow not found | `automation-infra-lab` precisa estar no GitHub com workflow na branch `main` |
| Private repos | `secrets: inherit` + mesmo org; reusable workflow em repo privado funciona na mesma org |

Layout local esperado:

```
.../automation-learn/automation-infra-lab/
.../automation-learn/automation-core-lab/
.../automation-learn/automation-web-lab/
.../automation-learn/automation-vision-lab/
```
