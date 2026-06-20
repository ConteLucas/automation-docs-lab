# Reiniciar a EC2 (lab)

Guia para quando a instância **parece travada**: SSH não responde, HTTP timeout, ou `/api/health` retorna **502/504** com nginx no ar.

## Dados do ambiente

| Item | Valor |
|------|-------|
| Elastic IP | `54.225.198.82` |
| Instance ID | `i-09f0d634fe8451653` |
| Região | `us-east-1` |
| Chave SSH | `~/.ssh/automation-learn-lab.pem` |

---

## Quando reiniciar

| Sintoma | Provável causa |
|---------|----------------|
| SSH: `Connection timed out during banner exchange` | SO sob carga (build Docker/Maven) ou instância travada |
| `curl` na porta 80 timeout | Serviços ou rede interna parados |
| Web **200** + `/api/health` **502/504** | Nginx ok, **core** ainda subindo ou crashando |
| Deploy cancelado com `Ctrl+C` no meio do build | EC2 pode ficar instável por alguns minutos |

**Não confunda** demora normal do core (Spring Boot, 1–3 min após reboot) com instância travada.

---

## Opção A — AWS CLI (mais prática no terminal)

Mesmo efeito do Console. Você já precisa do AWS CLI configurado (`aws sts get-caller-identity`).

```bash
# 1. Reiniciar (mantém IP, discos e configuração)
aws ec2 reboot-instances --region us-east-1 --instance-ids i-09f0d634fe8451653

# 2. Aguardar ~1–2 min (instância continua "running" durante o reboot)
sleep 90

# 3. Testar SSH
ssh -i ~/.ssh/automation-learn-lab.pem ec2-user@54.225.198.82 uptime

# 4. Aguardar o core subir (Spring Boot — pode levar 1–3 min)
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  code=$(curl -s -m 8 -o /dev/null -w "%{http_code}" "http://54.225.198.82/api/health" || echo "000")
  echo "tentativa $i: HTTP $code"
  [ "$code" = "200" ] && break
  sleep 15
done

curl -sf "http://54.225.198.82/api/health" && echo " OK"
```

**Reboot vs Stop/Start:** use `reboot-instances` (soft reboot). Só use stop/start se o reboot não resolver — o Elastic IP permanece, mas há mais downtime.

---

## Opção B — Console AWS

Útil se o CLI não estiver configurado ou preferir interface visual.

1. [EC2 Console](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:) → instância `automation-learn-lab-app` (ou IP `54.225.198.82`)
2. **Instance state** → **Reboot instance** → Confirmar
3. Aguarde **1–2 min** — status checks voltam a **2/2 passed**
4. Teste SSH e health (comandos acima)

O Console mostra visualmente quando os status checks passam; no CLI isso demora a refletir, por isso **parece travado** mesmo após o reboot — continue testando SSH/curl.

---

## Depois do reboot: precisa de deploy?

| Situação | Ação |
|----------|------|
| Só queria destravar a EC2 | **Não** — Docker sobe sozinho (`restart: unless-stopped`). Espere o core ficar healthy. |
| Alterou código local e quer publicar | **Sim** — rode deploy do serviço alterado |

```bash
cd automation-configs-lab
./infra-lab/scripts/deploy-service.sh core 54.225.198.82 ~/.ssh/automation-learn-lab.pem
```

Build do **core**: **~2–5 min no Mac** (Maven) + **~30 s na EC2** (só copia o JAR para imagem JRE). Antes compilava na `t4g.micro` e podia levar **horas**.

---

## Por que “parece travado” depois do reboot?

1. **Status checks AWS ≠ apps prontas** — a instância fica `running` e checks OK antes do Spring Boot aceitar tráfego.
2. **SSH lento nos primeiros minutos** — load average alto enquanto containers sobem (`docker compose` automático).
3. **502/504 é normal por ~1–3 min** — nginx sobe antes do core; health só fica **200** quando o Java termina de iniciar.
4. **Comando colado no terminal** — rode um comando por linha:

```bash
ssh -i ~/.ssh/automation-learn-lab.pem ec2-user@54.225.198.82 uptime
curl -sf "http://54.225.198.82/api/health"
```

(não junte `uptime` e `curl` na mesma linha sem `;` ou quebra de linha)

---

## Diagnóstico rápido (SSH funcionando)

```bash
ssh -i ~/.ssh/automation-learn-lab.pem ec2-user@54.225.198.82

cd /opt/automation-learn/src/automation-infra-lab
docker compose -f compose/docker-compose.prod.yml --env-file /opt/automation-learn/.env.prod ps -a
docker compose -f compose/docker-compose.prod.yml --env-file /opt/automation-learn/.env.prod logs core --tail=50
```

| Status do core | Significado |
|----------------|-------------|
| `(health: starting)` | Normal — aguarde até 2 min |
| `(healthy)` | OK |
| `Restarting` ou `(unhealthy)` | Ver logs; pode precisar de deploy ou fix no Postgres |

---

## Se reboot não resolver

1. Ver logs do core (comandos acima)
2. **Stop + Start** (último recurso):

```bash
aws ec2 stop-instances --region us-east-1 --instance-ids i-09f0d634fe8451653
aws ec2 wait instance-stopped --region us-east-1 --instance-ids i-09f0d634fe8451653
aws ec2 start-instances --region us-east-1 --instance-ids i-09f0d634fe8451653
aws ec2 wait instance-running --region us-east-1 --instance-ids i-09f0d634fe8451653
```

3. Validar infra completa: [AWS-VALIDATE.md](./AWS-VALIDATE.md)

---

## Documentos relacionados

- [AWS-VALIDATE.md](./AWS-VALIDATE.md) — checagens de rotina
- [DEPLOY-DEV.md](./DEPLOY-DEV.md) — deploy do dia a dia
- [GITHUB-DEPLOY.md](./GITHUB-DEPLOY.md) — CI/CD
