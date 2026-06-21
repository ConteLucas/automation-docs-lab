# automation-infra-lab — Arquitetura

Infraestrutura AWS de **baixo custo** para a plataforma DDT. Terraform provisiona uma EC2 única rodando o mesmo `docker-compose` do ambiente local, com S3 para imagens e Elastic IP para acesso fixo dos bots.

---

## Topologia AWS

```mermaid
graph TB
    subgraph internet["Internet"]
        ADMIN["Admin Web\n(browser)"]
        BOT["Bot Android\n(worker)"]
    end

    subgraph aws["AWS — default VPC"]
        direction TB
        EIP["Elastic IP\n(IP fixo gratuito\ncom instância ativa)"]

        subgraph ec2["EC2 t4g.micro — Amazon Linux 2023"]
            direction TB
            NGINX_LAYER["Nginx (no app-web)\nproxy :80 → /api, serve SPA"]

            subgraph docker_stack["Docker Compose Stack"]
                WEB["app-web\nReact/Nginx :80"]
                CORE["automation-core\nSpring Boot :8081"]
                VISION["automation-vision\nFastAPI :8000"]
                PG[("postgres :5432\n(volume EBS)")]
            end

            IAM_ROLE["IAM Role\nEC2 → S3 (sem access key)"]
        end

        S3["S3 Bucket\nautomation-device-lab/{ENV}/\nmacros + json/bot\n5 GB free tier"]
        EBS["EBS 30 GB gp3\n(dados Postgres + código)"]
    end

    ADMIN -->|HTTP :80| EIP
    BOT -->|HTTP :8000 X-Vision-Api-Key\nHTTP :80/api device API key| EIP
    EIP --> ec2
    WEB -->|/api proxy| CORE
    CORE --> PG
    CORE -->|IAM role sem credencial| S3
    ec2 --- EBS
    ec2 --- IAM_ROLE

    style aws fill:#fef3c7,stroke:#d97706
    style docker_stack fill:#dbeafe,stroke:#3b82f6
    style ec2 fill:#d1fae5,stroke:#059669
```

---

## Terraform — Recursos Provisionados

```mermaid
graph LR
    subgraph tf["Terraform (automation-infra-lab/terraform/)"]
        direction TB

        subgraph compute["Compute"]
            EC2_RES["aws_instance\nt4g.micro\nAmazon Linux 2023 ARM64"]
            EIP_RES["aws_eip\nElastic IP associado"]
            KEY["aws_key_pair\nSSH key (sua chave pública)"]
        end

        subgraph storage["Storage"]
            S3_RES["aws_s3_bucket\nautomation-learn-{suffix}\nautomation-device-lab/PROD/*"]
            S3_POL["aws_s3_bucket_policy\nprivate + IAM role only"]
            EBS_RES["aws_ebs_volume\n30 GB gp3 (via root block)"]
        end

        subgraph security["Security"]
            SG["aws_security_group\n:22 SSH (cidr restrito)\n:80 HTTP (0.0.0.0)\n:8000 Vision (0.0.0.0)\negress all"]
            ROLE["aws_iam_role\nautomation-ec2-role\n(S3 GetObject/PutObject)"]
            PROFILE["aws_iam_instance_profile\nassociado à EC2"]
        end

        subgraph init["User Data (bootstrap)"]
            UD["user-data.sh.tpl\ninstala Docker + Compose\nclona monorepo (opcional)\ncria .env.prod\ndocker compose up"]
        end
    end

    compute --> init
    ROLE --> PROFILE --> EC2_RES
    S3_POL --> S3_RES
    SG --> EC2_RES
```

---

## Stack Docker em Produção

```mermaid
graph TD
    subgraph compose["compose/docker-compose.prod.yml"]
        direction LR
        NGINX_SVC["app-web\n(nginx :80)\nserve dist/ + proxy /api"]
        CORE_SVC["core\n(spring boot :8081)\n(host network ou bridge)"]
        VISION_SVC["vision\n(fastapi :8000)\nX-Vision-Api-Key obrigatório"]
        PG_SVC["postgres\n(:5432)\nvolume local /var/lib/postgresql/data"]
    end

    NGINX_SVC -->|proxy /api| CORE_SVC
    CORE_SVC --> PG_SVC
    CORE_SVC -->|IAM role| S3_RES["S3"]
    VISION_SVC -.->|health check| CORE_SVC

    subgraph env[".env.prod (gerado pelo Terraform)"]
        V1["APP_TOKEN_SECRET"]
        V2["APP_GAME_ENCRYPTION_KEY"]
        V3["APP_STORAGE_MODE=s3"]
        V4["APP_STORAGE_S3_BUCKET"]
        V5["VISION_API_KEY"]
        V6["APP_SECURITY_WORKER_REQUIRE_DEVICE_KEY=true"]
        V7["SPRING_PROFILES_ACTIVE=prod"]
    end
```

---

## Fluxo de Deploy

```mermaid
sequenceDiagram
    participant DEV as Desenvolvedor
    participant TF as Terraform
    participant AWS as AWS
    participant EC2 as EC2 Instance
    participant GH as GitHub Actions (opcional)

    DEV->>TF: terraform apply
    TF->>AWS: cria EC2, EIP, S3, SG, IAM role
    AWS->>EC2: executa user-data.sh (Docker + clone + .env.prod)
    EC2->>EC2: docker compose up (core, vision, web, postgres)
    TF-->>DEV: outputs: EIP, S3 bucket, senhas geradas

    Note over DEV,EC2: Deploy de código (sem Terraform):
    DEV->>EC2: ./scripts/deploy-to-ec2.sh <IP> <key.pem>
    Note over EC2: rsync monorepo → EC2\ndocker compose down && up --build

    Note over GH,EC2: CI automático (opcional):
    GH->>EC2: push main → SSH → docker compose up --build
```

---

## Estimativa de Custo

```mermaid
pie title Custo mensal pós free tier (~US$ 9-11)
    "EC2 t4g.micro" : 6
    "EBS 30 GB gp3" : 2.4
    "S3 (templates)" : 0.5
    "Transferência" : 1
```

| Recurso | Free tier (12 meses) | Pós free tier |
|---------|----------------------|---------------|
| EC2 t4g.micro | ~US$ 0 | ~US$ 6/mês |
| EBS 30 GB gp3 | ~US$ 0 | ~US$ 2,4/mês |
| S3 (templates PNGs) | ~US$ 0 | < US$ 1/mês |
| Elastic IP | grátis se EC2 rodando | grátis se EC2 rodando |
| **Total** | **~US$ 0** | **~US$ 9–10/mês** |

---

## Segurança

```mermaid
graph LR
    subgraph net["Rede"]
        SSH["SSH :22\nrestrito por CIDR (allowed_ssh_cidr)"]
        HTTP["HTTP :80\npúblico (web + /api)"]
        VISION_PORT[":8000 Vision\npúblico (X-Vision-Api-Key obrigatório em prod)"]
        DB_PORT[":5432 Postgres\nNÃO exposto (só rede Docker interna)"]
    end

    subgraph app_sec["Aplicação"]
        JWT_S["JWT (HS256)\nusuários web"]
        DEVICE_KEY["Device API Key\nworkers Android (BCrypt hash)"]
        AES["AES-256-GCM\nsenhas de contas de jogo"]
        VISION_KEY["X-Vision-Api-Key\nbot → Vision API"]
    end

    subgraph aws_sec["AWS"]
        IAM_S["IAM Role\nEC2 acessa S3 sem credencial exposta"]
        IMDS["IMDSv2\nobrigatório (segurança metadata)"]
        SSM["SSM Session Manager\nalternativa ao SSH"]
    end
```

---

## Estrutura do Repositório

```
automation-infra-lab/
├── compose/
│   └── docker-compose.prod.yml  # Stack prod com paths *-lab
├── scripts/
│   └── deploy-to-ec2.sh         # rsync + restart containers
├── terraform/
│   ├── main.tf                  # EC2, EIP, S3, SG, IAM
│   ├── variables.tf             # ssh_key_name, allowed_ssh_cidr, etc.
│   ├── terraform.tfvars.example # template de config
│   ├── outputs.tf               # EIP, S3 bucket name, senhas
│   ├── iam-policy.terraform-lab.json # policy IAM mínima para terraform-lab
│   └── templates/
│       └── user-data.sh.tpl     # bootstrap da EC2 (Docker + .env.prod)
└── docs/
    ├── ARCHITECTURE.md          # este arquivo
    ├── GITHUB-DEPLOY.md         # CI/CD GitHub Actions
    ├── DATABASE-REVIEW.md       # operações no BD em prod
    ├── DOMAIN-SETUP.md          # domínio + HTTPS (certbot)
    └── env-images-s3.md         # configuração de storage S3
```

---

## O que não usamos (decisão de custo)

| Serviço AWS | Custo evitado | Alternativa |
|-------------|---------------|-------------|
| RDS PostgreSQL | ~US$ 15+/mês | Postgres no Docker (volume EBS) |
| NAT Gateway | ~US$ 32/mês | default VPC (acesso direto via EIP) |
| ALB (Load Balancer) | ~US$ 16+/mês | Nginx no app-web faz proxy |
| ECS Fargate / EKS | variável | docker-compose na EC2 |
| Multi-AZ / HA | variável | lab single-AZ |
