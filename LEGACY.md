# LEGACY — Mapeamento de Conteúdo em Desuso

Inventário de diretórios, arquivos e padrões que foram substituídos, descontinuados ou nunca foram ativados em produção. **Não deletar sem verificar dependências.** Revisitar antes de limpar.

---

## 1. automation-device-lab — Diretório `release/deprecado/` ✅ removido (2026-06-21)

Scripts de build e assets de AVD que foram movidos para `automation-device-lab/config/`. Pasta apagada; usar apenas `config/`.

---

## 2. Documentação de arquivo do bot ✅ removida (2026-06-21)

`automation-docs-lab/bot/archive/` (31 ficheiros `.md` históricos) e entradas git obsoletas em `configs/utils/docs/bot-ddt/docs/archive/` foram apagadas. Guias actuais em `automation-docs-lab/bot/`.

---

## 3. automation-bot-lab — Build Artifacts Commitados

**Caminho:** `automation-bot-lab/app/build/`

Diretório de build do Android Studio/Gradle. Contém APKs, classes compiladas, assets merged e outputs intermediários — não deve estar no controle de versão.

| Diretório | Conteúdo |
|-----------|---------|
| `app/build/outputs/apk/debug/app-debug.apk` | APK debug compilado (~MB) |
| `app/build/intermediates/` | Outputs intermediários do Gradle |
| `app/build/generated/` | Código gerado (R.java, BuildConfig...) |
| `app/build/kotlin/` | Cache de compilação Kotlin |
| `app/build/snapshot/` | Snapshots do Android Studio |

**Ação sugerida:** Adicionar `app/build/` ao `.gitignore` do `automation-bot-lab` e remover os arquivos rastreados com `git rm -r --cached app/build/`.

---

## 4. automation-core-lab — Build Artifact Commitado

**Caminho:** `automation-core-lab/target/`

Diretório de build do Maven. Contém o JAR compilado e relatório de cobertura.

| Arquivo | Conteúdo |
|---------|---------|
| `target/automation-core-ddt-1.0.jar` | JAR compilado (~MB) |
| `target/automation-core-ddt-1.0.jar.original` | JAR original pré-repackage |
| `target/jacoco.exec` | Dados de cobertura de testes |

**Ação sugerida:** Adicionar `target/` ao `.gitignore` do `automation-core-lab` e remover com `git rm -r --cached target/`.

---

## 5. automation-web-lab — Build e node_modules

**Caminhos:**
- `automation-web-lab/dist/` — build de produção (2574 arquivos JS, CSS, assets)
- `automation-web-lab/node_modules/` — 195 pacotes de dependências

Ambos nunca devem ser commitados.

**Ação sugerida:** Verificar `.gitignore` do `automation-web-lab` e remover com `git rm -r --cached dist/ node_modules/` se rastreados.

---

## 6. automation-db-lab — SQLs de Alter e Migrations Avulsas

**Caminho:** `automation-db-lab/sql/core/` e `automation-db-lab/sql/migrations/`

Scripts de alter e migrations pontuais que foram aplicados manualmente em algum momento. Com `ddl-auto=update` no perfil local, o Hibernate aplica mudanças automaticamente; esses scripts são referência histórica.

| Arquivo | Status |
|---------|--------|
| `sql/core/alter-game-account-account_status.sql` | Aplicado — coluna `account_status` já existe |
| `sql/core/alter-game-account-customer-order.sql` | Aplicado — relação customer/order no game_account |
| `sql/core/alter-task-device-nullable.sql` | Aplicado — task.device_id nullable |
| `sql/core/alter-user-notification.sql` | Aplicado — coluna de notificações no user |
| `sql/migrations/migration-add-flow-collection.sql` | Aplicado — hierarquia collection/flow |
| `sql/migrations/migration-flow-display-order.sql` | Aplicado — display_order nos flows |
| `sql/migrations/migration-flow-postgres.sql` | Aplicado — compatibilidade PostgreSQL |
| `sql/migrations/add-name_image-flow_step_image.sql` | Aplicado — campo name_image |
| `sql/migrations/add-worker_action-flow_step_image.sql` | Aplicado — worker_action no step_image |
| `sql/migrations/massa-flow-collections.sql` | Massa de dados de collections (dev only) |
| `sql/core/queries-teste.sql` | Queries de teste/debug — não é schema |
| `sql/core/game-accounts-import.csv` | CSV de importação de contas (dados sensíveis?) |

**Ação sugerida:**
- Verificar se `game-accounts-import.csv` contém dados reais — se sim, remover do git e adicionar ao `.gitignore`.
- Scripts `V*.sql` são histórico — manter como documentação.
- `alter-*.sql` e `migration-*.sql` avulsos podem ser deletados se o schema atual já os incorpora.

---

## 7. automation-configs-lab — Captures MITM e Arquivos Temporários

**Caminho:** `automation-configs-lab/utils/.local/ddt-traffic/captures/`

Capturas de tráfego HTTP geradas pelo mitmproxy durante sessões de debug.

| Arquivo | Conteúdo |
|---------|---------|
| `captures/flows-20260618-*.mitm` | Capturas de tráfego binário (mitmproxy) |
| `captures/summary-20260618-*.jsonl` | Resumos de requests em JSONL |
| `utils/.local/ddt-traffic/mitmdump.log` | Log do mitmdump |
| `utils/.local/ddt-traffic/mitmdump.pid` | PID file do processo |

**Ação sugerida:** Deletar `utils/.local/` (dados temporários de sessão). Adicionar ao `.gitignore`.

---

## 8. automation-configs-lab — Template de Credenciais Commitado

**Caminho:** `automation-configs-lab/ddt/worker-credentials.env`

Arquivo `.env` com credenciais de workers. Se contém valores reais (não apenas placeholders), representa risco de segurança.

**Ação sugerida:** Auditar conteúdo. Se tiver credenciais reais → remover do git history com `git filter-repo` ou `BFG Repo Cleaner`. Manter apenas um `.env.example`.

---

## 9. automation-learn/.local — Diretório Temporário Local

**Caminho:** `automation-learn/.local/`

Contém pulls temporários de outros repos e dados de sessão local.

| Subdir | Conteúdo |
|--------|---------|
| `.local/tmp-device-lab-pull/` | Pull temporário do device-lab para revisão |
| `.local/tmp-device-release-check/` | Verificação de release do device-lab |

**Ação sugerida:** Deletar `.local/` e adicionar ao `.gitignore` raiz.

---

## 10. .DS_Store Files

19 arquivos `.DS_Store` (macOS Finder metadata) commitados nos repositórios.

**Ação sugerida:**
```bash
# Em cada repo (ou na pasta local automation-learn/)
find . -name ".DS_Store" | xargs git rm --cached 2>/dev/null
echo ".DS_Store" >> .gitignore
```

---

## Resumo por Prioridade

| Prioridade | Item | Risco |
|------------|------|-------|
| 🔴 ALTA | `ddt/worker-credentials.env` — possíveis credenciais reais | Segurança |
| 🔴 ALTA | `sql/core/game-accounts-import.csv` — possíveis dados sensíveis | Segurança |
| 🟠 MÉDIA | `app/build/` no bot-lab — build artifacts no git | Repositório inflado |
| 🟠 MÉDIA | `target/` no core-lab — JAR compilado no git | Repositório inflado |
| 🟠 MÉDIA | `dist/` e `node_modules/` no web-lab — se rastreados | Repositório inflado |
| 🟡 BAIXA | `.local/` (capturas MITM, tmp pulls) | Dados temporários no git |
| 🟢 INFO | `.DS_Store` (19 arquivos) | Metadados macOS |
| 🟢 INFO | `alter-*.sql` / `migration-*.sql` avulsos | Histórico já aplicado |
