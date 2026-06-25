# Revisar o banco Postgres (lab)

Como **listar tabelas**, rodar `**SELECT`** e inspecionar dados no Postgres da EC2.

O banco **não é RDS** — roda no container Docker `automation-db`, **sem porta exposta na internet**. Acesso só via **SSH** (ou túnel SSH + GUI).

## Dados do ambiente


| Item             | Valor                                                              |
| ---------------- | ------------------------------------------------------------------ |
| EC2 (Elastic IP) | `54.225.198.82`                                                    |
| Container        | `automation-db`                                                    |
| Imagem           | `postgres:16-alpine`                                               |
| Database         | `automation_db`                                                    |
| Usuário          | `postgres`                                                         |
| Senha            | em `/opt/automation-learn/.env.prod` (`DB_PASSWORD`)               |
| Rede Docker      | `automation-learn-app` (interna — core conecta em `postgres:5432`) |


---

## Passo a passo — DBeaver (todo dia / após reiniciar o Mac)

Você **já conectou** quando o DBeaver mostra `automation-learn-lab` (ou sua conexão) e consegue ver tabelas em **Schemas → public → Tables**.

O `localhost:5433` no DBeaver **não** é banco local — é a porta do **túnel SSH** até o Postgres **na EC2**. Depois de reiniciar o Mac, o túnel **some**; é preciso subir de novo (a conexão salva no DBeaver continua válida).

### Primeira vez (configurar uma vez só)

**1. Instalar DBeaver** — [https://dbeaver.io/download/](https://dbeaver.io/download/)

**2. Criar conexão** — DBeaver → **Database → New Database Connection → PostgreSQL**


| Aba      | Campo         | Valor                          |
| -------- | ------------- | ------------------------------ |
| **Main** | Host          | `localhost`                    |
| **Main** | Port          | `5433`                         |
| **Main** | Database      | `automation_db`                |
| **Main** | Username      | `postgres`                     |
| **Main** | Password      | (passo 3 abaixo)               |
| **Main** | Save password | ✅ marcado                      |
| **SSH**  | —             | **desligado** (sem túnel aqui) |


**3. Senha** — no Terminal:

```bash
ssh -i ~/.ssh/automation-learn-lab.pem ec2-user@54.225.198.82 \
  "grep '^DB_PASSWORD=' /opt/automation-learn/.env.prod | cut -d= -f2-"
```

Cole no DBeaver → **Test Connection** → **Finish**.

*(Opcional: importar `templates/dbeaver/data-sources.json` — ver seção 3.)*

---

### Toda vez que for usar (ou após reiniciar o PC)

Ordem: **túnel primeiro**, **DBeaver depois**.

**Opção A — script:**

```bash
cd ~/Developer/git/automation-learn/automation-configs-lab
./db-lab/scripts/dbeaver-tunnel.sh
```

**Opção B — só comandos (sem `.sh`):** veja seção [Comandos manuais (sem script)](#comandos-manuais-sem-script) abaixo.

**Passo 2 — Abrir DBeaver** e clicar na conexão **automation-learn-lab** (duplo clique ou expandir).

**Passo 3 — Consultar**

- Tabelas: `automation_db → Schemas → public → Tables`
- SQL: botão **SQL Editor** → `SELECT * FROM user_admin LIMIT 10;` → `Cmd+Enter`

---

### Comandos manuais (sem script)

O script `dbeaver-tunnel.sh` faz **exatamente** isto:

**1. Descobrir o IP do container Postgres na EC2**

```bash
ssh -i ~/.ssh/automation-learn-lab.pem ec2-user@54.225.198.82 \
  "docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' automation-db"
```

Anote a saída (ex.: `172.18.0.4`). **Muda** se o container for recriado.

**2. Abrir o túnel SSH** (Mac → EC2 → Postgres)

Substitua `172.18.0.4` pelo IP do passo 1:

```bash
ssh -i ~/.ssh/automation-learn-lab.pem \
  -L 5433:172.18.0.4:5432 \
  ec2-user@54.225.198.82 -N
```


| Flag                      | Significado                                                        |
| ------------------------- | ------------------------------------------------------------------ |
| `-L 5433:172.18.0.4:5432` | No Mac, porta **5433** encaminha para **5432** do container na EC2 |
| `-N`                      | Não abre shell remoto — só o túnel                                 |
| (sem `-f`)                | Terminal **fica aberto**; fechar = túnel cai                       |


Para rodar em **background** (terminal livre), igual ao script:

```bash
ssh -i ~/.ssh/automation-learn-lab.pem \
  -f -N -L 5433:172.18.0.4:5432 \
  ec2-user@54.225.198.82
```

**3. Testar se o túnel está ativo**

```bash
nc -zv localhost 5433
```

Esperado: `Connection to localhost port 5433 succeeded!`

**4. Senha do banco** (se precisar no DBeaver)

```bash
ssh -i ~/.ssh/automation-learn-lab.pem ec2-user@54.225.198.82 \
  "grep '^DB_PASSWORD=' /opt/automation-learn/.env.prod | cut -d= -f2-"
```

**5. DBeaver** — aba **Main**, SSH **desligado**:


| Host        | Port   | Database        | User       |
| ----------- | ------ | --------------- | ---------- |
| `localhost` | `5433` | `automation_db` | `postgres` |


**6. Encerrar o túnel**

Se abriu com `-f` (background):

```bash
pkill -f "ssh.*-L 5433:172.18.0.4:5432"
```

(Substitua o IP se for outro.) Ou feche o terminal se usou `-N` sem `-f`.

---

### Checklist rápido


| #   | O quê           | Comando / ação                                                           |
| --- | --------------- | ------------------------------------------------------------------------ |
| 1   | Túnel ativo?    | `nc -zv localhost 5433` → `succeeded`                                    |
| 2   | Subir túnel     | `../automation-configs-lab/db-lab/scripts/dbeaver-tunnel.sh` **ou** `ssh -L 5433:IP_CONTAINER:5432 ...` |
| 3   | DBeaver         | Conexão `localhost:5433` / `automation_db`                               |
| 4   | Senha esquecida | `grep DB_PASSWORD` via SSH (comando acima)                               |


---

### Se der erro após reboot


| Sintoma                                  | O que fazer                                                                                             |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `Connection refused` em `localhost:5433` | Rode `./scripts/dbeaver-tunnel.sh` de novo                                                              |
| `password authentication failed`         | Copie de novo o `DB_PASSWORD` na EC2                                                                    |
| Conexão pendurada / timeout              | EC2 lenta — teste `ssh ec2-user@54.225.198.82 uptime`; ver [RESTART-INSTANCE.md](./RESTART-INSTANCE.md) |


---

### Alternativa: só terminal (sem DBeaver)

```bash
ssh -i ~/.ssh/automation-learn-lab.pem ec2-user@54.225.198.82
docker exec -it automation-db psql -U postgres -d automation_db
```

---

## Onde **não** ver o banco


| Local                                  | Por quê                                             |
| -------------------------------------- | --------------------------------------------------- |
| Console AWS (RDS)                      | Não existe RDS neste lab                            |
| Internet direta (`54.225.198.82:5432`) | Porta **não** aberta no security group (proposital) |
| CloudWatch                             | Não monitora tabelas SQL                            |


---

## 1. Senha do banco

**Na EC2** (via SSH):

```bash
ssh -i ~/.ssh/automation-learn-lab.pem ec2-user@54.225.198.82
grep DB_PASSWORD /opt/automation-learn/.env.prod
```

**No Mac** (se ainda tiver o output do Terraform após o 1º `apply`):

```bash
cd automation-infra-lab/terraform
terraform output -json generated_secrets_note | jq -r '.db_password'
```

---

## 2. Terminal — `psql` no container (recomendado)

SSH na EC2:

```bash
ssh -i ~/.ssh/automation-learn-lab.pem ec2-user@54.225.198.82
```

Entrar no Postgres interativo:

```bash
docker exec -it automation-db psql -U postgres -d automation_db
```

### Comandos úteis no `psql`

```sql
\dt                    -- listar tabelas
\dt+                   -- tabelas + tamanho
\d user_admin          -- colunas de uma tabela
\dn                    -- schemas
\q                     -- sair
```

### `SELECT` sem abrir shell interativo

```bash
docker exec automation-db psql -U postgres -d automation_db -c "\dt"

docker exec automation-db psql -U postgres -d automation_db -c \
  "SELECT id, login, email, active FROM user_admin LIMIT 10;"

docker exec automation-db psql -U postgres -d automation_db -c \
  "SELECT id, status, created_at FROM sales_order ORDER BY id DESC LIMIT 5;"

docker exec automation-db psql -U postgres -d automation_db -c \
  "SELECT id, status, sales_order_id FROM task ORDER BY id DESC LIMIT 10;"

docker exec automation-db psql -U postgres -d automation_db -c \
  "SELECT id, identifier, active FROM device LIMIT 10;"
```

### Contagens rápidas

```bash
docker exec automation-db psql -U postgres -d automation_db -c "
SELECT 'user_admin' AS t, count(*) FROM user_admin
UNION ALL SELECT 'sales_order', count(*) FROM sales_order
UNION ALL SELECT 'task', count(*) FROM task
UNION ALL SELECT 'device', count(*) FROM device;
"
```

---

## 3. DBeaver no Mac (passo a passo)

O Postgres **não** escuta em `54.225.198.82:5432`. Ele fica **dentro do Docker**, numa rede interna. O DBeaver precisa de **túnel SSH** até a EC2 e, depois, apontar para o **IP do container**.

### Antes de abrir o DBeaver

**1. Instale o DBeaver** (Community Edition): [https://dbeaver.io/download/](https://dbeaver.io/download/)

**2. Pegue a senha do banco** (guarde num bloco de notas):

```bash
ssh -i ~/.ssh/automation-learn-lab.pem ec2-user@54.225.198.82 \
  "grep '^DB_PASSWORD=' /opt/automation-learn/.env.prod | cut -d= -f2-"
```

**3. Descubra o IP do container Postgres** (anote — muda se recriar o container):

```bash
ssh -i ~/.ssh/automation-learn-lab.pem ec2-user@54.225.198.82 \
  "docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' automation-db"
```

Exemplo de saída: `172.18.0.4` → use esse valor no passo abaixo como **Host do banco** (o IP **muda**; sempre rode o comando acima).

**Atalho (recomendado):** script que abre o túnel e mostra os valores para colar no DBeaver:

```bash
cd automation-infra-lab
./scripts/dbeaver-tunnel.sh
```

**Opcional: importar conexão pronta** (pode pular — veja passo a passo abaixo)

Só economiza digitar Host/Port/Database. A **senha** você informa na 1ª conexão.

1. Rode o túnel **antes**: `../automation-configs-lab/db-lab/scripts/dbeaver-tunnel.sh`
2. DBeaver → menu **Database** → **Import connections**
  *(Se não achar: **File → Import → DBeaver → Connections**.)*
3. **Browse** → selecione o arquivo:
  `automation-infra-lab/templates/dbeaver/data-sources.json`
4. Marque a conexão **automation-learn-lab** → **Finish**
5. No painel esquerdo, clique duas vezes em **automation-learn-lab**
6. Cole a **Password** (comando `grep DB_PASSWORD` abaixo) → **Test Connection** → **OK**



---

### Método A — Tudo dentro do DBeaver (recomendado)

Um único lugar configura SSH + Postgres.

**Passo 1 — Nova conexão**

- Menu **Database → New Database Connection**
- Escolha **PostgreSQL** → **Next**
- Se pedir download do driver JDBC, clique **Download**

**Passo 2 — Aba `Main` (PostgreSQL)**

Preencha **exatamente**:


| Campo             | Valor                                                                             |
| ----------------- | --------------------------------------------------------------------------------- |
| **Host**          | IP do container (ex.: `172.18.0.2`) — **não** use `54.225.198.82` nem `localhost` |
| **Port**          | `5432`                                                                            |
| **Database**      | `automation_db`                                                                   |
| **Username**      | `postgres`                                                                        |
| **Password**      | valor do `DB_PASSWORD` (passo “Antes”)                                            |
| **Save password** | ✅ marque para não digitar sempre                                                  |


**Passo 3 — Aba `SSH`**

Marque **Use SSH Tunnel** e preencha:


| Campo                     | Valor                                                 |
| ------------------------- | ----------------------------------------------------- |
| **Host/IP**               | `54.225.198.82`                                       |
| **Port**                  | `22`                                                  |
| **Username**              | `ec2-user`                                            |
| **Authentication Method** | **Public Key**                                        |
| **Private Key**           | clique **Browse** → `~/.ssh/automation-learn-lab.pem` |
| **Passphrase**            | deixe vazio (a menos que sua chave tenha senha)       |


**Passo 4 — Testar**

- Clique **Test Connection**
- Primeira vez: DBeaver pode baixar drivers — aceite
- Sucesso: mensagem **Connected**
- Clique **Finish**

**Passo 5 — Navegar nas tabelas**

No painel esquerdo:

```
automation_db → Schemas → public → Tables
```

Clique com botão direito numa tabela → **View Data** → **All Rows** (ou abra **SQL Editor** com `Ctrl+Enter` / `Cmd+Enter`).

Exemplo no editor SQL:

```sql
SELECT id, login, email FROM user_admin LIMIT 20;
```

---

### Método B — Túnel SSH manual + DBeaver simples

Use se o Método A der erro de rede. São **dois passos**: terminal aberto + DBeaver sem aba SSH.

**Terminal 1** (deixe rodando — não feche):

Substitua `172.18.0.2` pelo IP real do container:

```bash
ssh -i ~/.ssh/automation-learn-lab.pem \
  -L 5433:172.18.0.2:5432 \
  ec2-user@54.225.198.82 -N
```

Não aparece nada na tela — é normal. O túnel está ativo.

**DBeaver — aba `Main` apenas** (aba **SSH desmarcada**):


| Campo        | Valor           |
| ------------ | --------------- |
| **Host**     | `localhost`     |
| **Port**     | `5433`          |
| **Database** | `automation_db` |
| **Username** | `postgres`      |
| **Password** | `DB_PASSWORD`   |


**Test Connection** → **Finish**.

---

### O que **não** funciona


| Configuração errada                                          | Por quê                                      |
| ------------------------------------------------------------ | -------------------------------------------- |
| Host = `54.225.198.82`, Port = `5432`                        | Porta 5432 fechada na internet               |
| Host = `localhost`, Port = `5432`, sem túnel                 | Postgres não roda no seu Mac                 |
| Host = `localhost` na aba Main **com** SSH tunnel (Método A) | Dentro da EC2, `localhost` não é o container |
| Esqueceu de atualizar o IP do container                      | Após `docker compose down/up` o IP muda      |


---

### Problemas comuns


| Erro                                       | Solução                                                                                |
| ------------------------------------------ | -------------------------------------------------------------------------------------- |
| `Connection refused` / timeout             | Refaça o comando do IP do container; confira se `automation-db` está up (`docker ps`)  |
| `password authentication failed`           | Copie de novo o `DB_PASSWORD` do `.env.prod`                                           |
| `Permission denied (publickey)` na aba SSH | Caminho correto da chave `.pem`; permissão `chmod 600 ~/.ssh/automation-learn-lab.pem` |
| SSH lento / timeout                        | EC2 sob carga — aguarde ou veja [RESTART-INSTANCE.md](./RESTART-INSTANCE.md)           |
| Túnel manual caiu                          | Terminal com `-N` foi fechado — abra de novo                                           |


---

### Outras GUIs (TablePlus, pgAdmin)

Mesma lógica do DBeaver: **SSH para a EC2** + **host = IP do container** + porta `5432`, ou túnel manual `localhost:5433` como no Método B.

---

## 4. Tabelas principais (Core)

Schema gerenciado pelo Hibernate (`ddl-auto: update` no lab). Referência completa:

`automation-docs-lab/db/docs/CORE-DATABASE-TABLES.md`


| Tabela                    | Conteúdo                           |
| ------------------------- | ---------------------------------- |
| `user_admin`              | Utilizadores do admin web          |
| `permission`              | Perfis (ADM, DEV, MANAGER, SELLER) |
| `sales_order`             | Pedidos de venda                   |
| `task`                    | Tarefas do orquestrador            |
| `device`                  | Dispositivos / workers Android     |
| `flow` / `flow_step`      | Fluxos do bot                      |
| `server` / `range_server` | Servidores do jogo (1–65)          |
| `game_account`            | Contas do jogo                     |
| `customer`                | Clientes (CRM)                     |


---

## 5. Utilizadores de teste (login web)

Se o login falhar ou a tabela estiver vazia:

```bash
cd automation-configs-lab
./core-lab/scripts/seed-ec2-users.sh 54.225.198.82 ~/.ssh/automation-learn-lab.pem
```


| Login   | Senha   | Perfil  |
| ------- | ------- | ------- |
| admin   | admin   | ADM     |
| dev     | dev     | DEV     |
| manager | manager | MANAGER |
| seller  | seller  | SELLER  |


Teste: `http://54.225.198.82/login` ou `http://automation-device-lab.com/login`

---

## 6. Verificar se o Postgres está saudável

```bash
ssh -i ~/.ssh/automation-learn-lab.pem ec2-user@54.225.198.82 \
  "docker compose -f /opt/automation-learn/src/automation-infra-lab/compose/docker-compose.prod.yml \
    --env-file /opt/automation-learn/.env.prod ps postgres"
```

Esperado: `(healthy)`.

Logs:

```bash
docker compose -f /opt/automation-learn/src/automation-infra-lab/compose/docker-compose.prod.yml \
  --env-file /opt/automation-learn/.env.prod logs postgres --tail=50
```

---

## 7. Cuidados (lab)

- `**SELECT**` — livre para inspecionar.
- `**UPDATE` / `DELETE` / `DROP**` — evite em produção real; no lab pode quebrar login, tasks ou flows.
- **Backup** — volume Docker `postgres_data` na EC2. Backup manual (futuro): `pg_dump` → S3 (ver README).
- **Não** abra a porta 5432 no security group só para facilitar a GUI — use SSH/túnel.

---

## 8. Trocar senha do Postgres (e evitar 502)

Se expôs a senha ou quer rotacionar:

**1. Gerar senha nova** (na EC2):

```bash
openssl rand -base64 24 | tr -d '/+=' | head -c 24
```

**2. Alterar no Postgres** (substitua `SENHA_NOVA`):

```bash
docker exec automation-db psql -U postgres -c "ALTER USER postgres PASSWORD 'SENHA_NOVA';"
```

**3. Atualizar `.env.prod`:**

```bash
sudo sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=SENHA_NOVA|" /opt/automation-learn/.env.prod
```

**4. Recriar containers** — `**restart` não basta** (mantém env antiga):

```bash
cd /opt/automation-learn/src/automation-infra-lab
docker compose -f compose/docker-compose.prod.yml \
  --env-file /opt/automation-learn/.env.prod up -d core app-web
```

**5. Aguardar ~1–2 min** e testar:

```bash
curl -sf http://localhost/api/health
```

**6. Atualizar senha no DBeaver.**

### Se o site mostrar 502 após trocar senha


| Causa                  | Log / sintoma                                        | Correção                              |
| ---------------------- | ---------------------------------------------------- | ------------------------------------- |
| Core com senha antiga  | `password authentication failed for user "postgres"` | Passo 4: `up -d core` (não `restart`) |
| Nginx sem achar o core | Core `(healthy)` mas `/api/health` = 502             | `up -d app-web`                       |
| Senha divergente       | Postgres OK no `ALTER` mas `.env.prod` errado        | Alinhar passos 2 e 3                  |


---

## Documentos relacionados

- [AWS-VALIDATE.md](./AWS-VALIDATE.md) — validar EC2 e serviços
- [DEPLOY-DEV.md](./DEPLOY-DEV.md) — deploy e `seed-ec2-users.sh`
- [RESTART-INSTANCE.md](./RESTART-INSTANCE.md) — EC2 travada
- [README](../README.md) — arquitetura (Postgres no EC2 vs RDS)

