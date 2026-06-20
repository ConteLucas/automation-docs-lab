# Validar infra AWS (lab)

Comandos para checar credenciais, Terraform, EC2, S3, IAM e saúde das aplicações no ambiente **automation-learn-lab**.

## Dados do ambiente

| Item | Valor |
|------|-------|
| Elastic IP | `54.225.198.82` |
| Domínio | `http://automation-device-lab.com` |
| Região | `us-east-1` |
| Usuário SSH | `ec2-user` |
| Chave SSH | `~/.ssh/automation-learn-lab.pem` |
| Prefixo dos recursos | `automation-learn-lab` |
| Security group | `automation-learn-lab-app` |

Se a infra mudar, confira também:

```bash
cd automation-infra-lab/terraform
terraform output public_ip
terraform output s3_bucket_name
```

---

## 1. Credenciais e permissões

Confirme que o AWS CLI está autenticado e com permissões suficientes (EC2, S3, IAM):

```bash
aws sts get-caller-identity
aws ec2 describe-vpcs --max-results 5 --region us-east-1
```

Esperado: retorno com `Account`, `UserId` e `Arn`. Erro `not authorized` → ajuste IAM (ver [README](../README.md#permissoes-iam-obrigatorio)).

---

## 2. Terraform (IaC)

Na pasta `automation-infra-lab/terraform`:

```bash
terraform fmt -check -recursive    # formatação
terraform validate                 # sintaxe e referências
terraform plan                     # diff vs estado (sem aplicar)
terraform output                   # IPs, bucket, URLs
terraform output -json generated_secrets_note   # senhas geradas (1º apply)
```

| Comando | O que valida |
|---------|--------------|
| `validate` | HCL correto, providers OK |
| `plan` | Recursos que seriam criados/alterados |
| `output` | Valores reais após `apply` |

---

## 3. EC2 e rede

```bash
# Instância rodando
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:Project,Values=automation-learn" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name,IP:PublicIpAddress,Type:InstanceType}' \
  --output table

# Status checks (2/2 = saudável)
aws ec2 describe-instance-status \
  --region us-east-1 \
  --include-all-instances \
  --output table

# Elastic IP associado
aws ec2 describe-addresses \
  --region us-east-1 \
  --query 'Addresses[].{IP:PublicIp,Instance:InstanceId}' \
  --output table

# Security group (portas 22, 80, 443, 8000)
aws ec2 describe-security-groups \
  --region us-east-1 \
  --filters "Name=group-name,Values=automation-learn-lab-app" \
  --query 'SecurityGroups[].IpPermissions' \
  --output json
```

Teste de conectividade (do Mac):

```bash
nc -zv 54.225.198.82 22    # SSH
nc -zv 54.225.198.82 80    # Web
nc -zv 54.225.198.82 8000  # Vision (se exposto)
```

---

## 4. S3

```bash
cd automation-infra-lab/terraform
BUCKET=$(terraform output -raw s3_bucket_name)

aws s3 ls "s3://${BUCKET}/" --region us-east-1
aws s3api head-bucket --bucket "$BUCKET" --region us-east-1
aws s3api get-bucket-encryption --bucket "$BUCKET" --region us-east-1
aws s3api get-bucket-versioning --bucket "$BUCKET" --region us-east-1
aws s3api get-public-access-block --bucket "$BUCKET" --region us-east-1
```

---

## 5. IAM (role da EC2)

```bash
aws iam list-instance-profiles-for-role --role-name automation-learn-lab-ec2
aws iam get-role --role-name automation-learn-lab-ec2
```

Na EC2, teste se a role acessa o S3 (via SSM — ver seção 6):

```bash
aws s3 ls "s3://<bucket>/img/flows/" --region us-east-1
```

---

## 6. Acesso à EC2 (SSH ou SSM)

```bash
# SSH
ssh -i ~/.ssh/automation-learn-lab.pem ec2-user@54.225.198.82

# SSM (alternativa sem .pem)
INSTANCE_ID=$(aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:Name,Values=automation-learn-lab-app" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

aws ssm start-session --target "$INSTANCE_ID" --region us-east-1
```

Dentro da instância — validar stack Docker:

```bash
cd /opt/automation-learn/src/automation-infra-lab
docker compose -f compose/docker-compose.prod.yml ps
docker compose -f compose/docker-compose.prod.yml logs --tail=50
```

---

## 7. Health checks por serviço

Do Mac:

```bash
# Web (nginx + frontend)
curl -sf -o /dev/null -w "web: %{http_code}\n" "http://54.225.198.82/"

# Core API
curl -sf "http://54.225.198.82/api/health" && echo " OK"

# Vision ( /health não exige API key )
curl -sf "http://54.225.198.82:8000/health" && echo " OK"
```

Via domínio:

```bash
dig +short automation-device-lab.com
curl -sf -o /dev/null -w "HTTP %{http_code}\n" "http://automation-device-lab.com/login"
```

Dentro da EC2 — status por container:

```bash
docker compose -f compose/docker-compose.prod.yml --env-file /opt/automation-learn/.env.prod ps -a
docker compose -f compose/docker-compose.prod.yml --env-file /opt/automation-learn/.env.prod logs core --tail=30
docker compose -f compose/docker-compose.prod.yml --env-file /opt/automation-learn/.env.prod logs app-web --tail=30
docker compose -f compose/docker-compose.prod.yml --env-file /opt/automation-learn/.env.prod logs vision --tail=30
```

| Container | Serviço | Health |
|-----------|---------|--------|
| `automation-app-web` | Web | HTTP 200 em `/` |
| `automation-core` | Core | `/api/health` → `{"status":"UP"}` |
| `automation-vision` | Vision | `:8000/health` |
| `automation-db` | Postgres | `(healthy)` no `docker ps` |

---

## 8. Checklist rápido

| Etapa | Comando |
|-------|---------|
| Auth AWS | `aws sts get-caller-identity` |
| IaC | `terraform plan` (sem changes inesperados) |
| EC2 up | `describe-instances` + status checks 2/2 |
| Rede | `nc -zv 54.225.198.82 80` |
| S3 | `aws s3 ls s3://<bucket>/` |
| Apps | `curl http://54.225.198.82/api/health` |
| Containers | `docker compose ps` (via SSH/SSM) |

---

## Ordem recomendada

1. `aws sts get-caller-identity`
2. `terraform output` → confirme IP e bucket
3. `describe-instances` + status checks
4. `curl` nos endpoints de health
5. SSH/SSM → `docker compose ps`

---

## Documentos relacionados

- [DATABASE-REVIEW.md](./DATABASE-REVIEW.md) — Postgres: tabelas, SELECT, DBeaver
- [RESTART-INSTANCE.md](./RESTART-INSTANCE.md) — EC2 travada ou health 502/504
- [DEPLOY-DEV.md](./DEPLOY-DEV.md) — deploy do dia a dia
- [GITHUB-DEPLOY.md](./GITHUB-DEPLOY.md) — CI/CD via GitHub Actions
- [DOMAIN-SETUP.md](./DOMAIN-SETUP.md) — domínio e HTTPS
- [README](../README.md) — arquitetura e `terraform apply`
