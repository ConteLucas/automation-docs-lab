# Índice da documentação — Bot Android

Navegação dos guias do worker (`automation-bot-lab`). Os nomes dos ficheiros seguem um prefixo que indica o tipo de conteúdo.

**Convenção de nomes**

| Prefixo | Significado | Exemplo |
|---------|-------------|---------|
| `guia-` | Como fazer / operacional | `guia-execucao-task-core.md` |
| `ref-` | Referência rápida ou consulta | `ref-comandos-rapidos.md` |
| `arq-` | Arquitetura e diagramas | `arq-visao-geral-bot.md` |
| `dev-` | Desenvolvimento e contribuição | `dev-padroes-codigo.md` |
| `core-` | Integração com o Core API | `core-estrategia-requests-api.md` |
| `runbook-` | Procedimento copiar/colar (ops) | `runbook-mitm-emulador.md` |
| `testes-` | Relatórios de testes | `testes-resumo.md` |

**Última atualização:** 2026-06-20

---

## Início rápido

| Ficheiro | O que é | Tempo |
|----------|---------|-------|
| [guia-setup-inicial.md](guia-setup-inicial.md) | Instalar e arrancar o projeto | 5 min |
| [ref-comandos-rapidos.md](ref-comandos-rapidos.md) | Comandos e fluxos do dia a dia | 3 min |
| [ref-status-projeto.md](ref-status-projeto.md) | Estado actual (pode estar desactualizado) | 2 min |

---

## Execução de tasks e Core

| Ficheiro | O que é |
|----------|---------|
| [guia-execucao-task-core.md](guia-execucao-task-core.md) | **Ciclo completo L1–L5** — claim-next, pré-voo, manifest, status |
| [guia-orquestrador-task-core.md](guia-orquestrador-task-core.md) | Orquestrador × Core — plano `flow_step` / `flow_step_image` |
| [ref-acoes-worker-manifest.md](ref-acoes-worker-manifest.md) | Acções `CLICK`, `WAIT_APPEAR`, `IF_VISIBLE` no manifest |
| [guia-sync-manifests-s3.md](guia-sync-manifests-s3.md) | Sincronizar flows e PNG via S3 antes do claim |
| [guia-login-servidor-mitm.md](guia-login-servidor-mitm.md) | Login A11y + servidor variável (mitm rewrite S10/S12…) |
| [runbook-mitm-emulador.md](runbook-mitm-emulador.md) | Cert system + mitm no Mac (copiar/colar) |

---

## Captura, Vision e UI

| Ficheiro | O que é |
|----------|---------|
| [guia-captura-screenshot.md](guia-captura-screenshot.md) | MediaProjection — captura de ecrã |
| [guia-vision-api-templates.md](guia-vision-api-templates.md) | Template matching (`/lens`, `/match`, OCR) |
| [guia-cliques-acessibilidade.md](guia-cliques-acessibilidade.md) | Cliques via Accessibility Service |
| [guia-interface-flutuante.md](guia-interface-flutuante.md) | Janela flutuante e efeitos visuais |
| [guia-sistema-logs.md](guia-sistema-logs.md) | Logs unificados e depuração |
| [guia-permissoes-android.md](guia-permissoes-android.md) | Permissões do manifest |

---

## Arquitetura

| Ficheiro | O que é |
|----------|---------|
| [arq-visao-geral-bot.md](arq-visao-geral-bot.md) | **Visão macro** — camadas, BotFactory, integrações |
| [arq-fluxo-camadas-e-diagramas.md](arq-fluxo-camadas-e-diagramas.md) | Fluxo MVVM e responsabilidades |
| [arq-diagrama-sequencia-botfactory.md](arq-diagrama-sequencia-botfactory.md) | Diagramas Mermaid (grafo + sequência) |
| [arq-analise-detalhada.md](arq-analise-detalhada.md) | Análise arquitectural aprofundada |
| [arq-arvore-classes-acoplamento.md](arq-arvore-classes-acoplamento.md) | Árvore de classes e acoplamento |
| [arq-refatoracao-clean-architecture.md](arq-refatoracao-clean-architecture.md) | Plano de refactor clean architecture |
| [arq-documentacao-legacy-mvvm.md](arq-documentacao-legacy-mvvm.md) | Doc histórica MVVM (fase inicial) |

---

## Core API (contratos e dados)

| Ficheiro | O que é |
|----------|---------|
| [core-estrategia-requests-api.md](core-estrategia-requests-api.md) | Estratégia de requests ao Core |
| [core-revisao-modelo-dados.md](core-revisao-modelo-dados.md) | Revisão crítica do modelo |
| [core-mapeamento-dto-entity.md](core-mapeamento-dto-entity.md) | Mapeamento DTO ↔ entidades |

---

## Desenvolvimento

| Ficheiro | O que é |
|----------|---------|
| [dev-workflow-build-testes.md](dev-workflow-build-testes.md) | Build, deploy, testes |
| [dev-padroes-codigo.md](dev-padroes-codigo.md) | Convenções de código |
| [ref-config-application-properties.md](ref-config-application-properties.md) | `application.properties` e perfis |
| [dev-notas-backup-v4.md](dev-notas-backup-v4.md) | Notas de backup v4 (legado) |

---

## Testes

| Ficheiro | O que é |
|----------|---------|
| [testes-resumo.md](testes-resumo.md) | Resumo dos testes |
| [testes-relatorio-cobertura.md](testes-relatorio-cobertura.md) | Relatório de cobertura |

---

## Por objectivo

**Quero executar tasks do Core**
1. [guia-execucao-task-core.md](guia-execucao-task-core.md)
2. [guia-login-servidor-mitm.md](guia-login-servidor-mitm.md)
3. Core: [TASK-WORKER-CLAIM.md](../core/TASK-WORKER-CLAIM.md)

**Quero perceber a arquitectura**
1. [arq-visao-geral-bot.md](arq-visao-geral-bot.md)
2. [guia-execucao-task-core.md](guia-execucao-task-core.md)
3. [arq-diagrama-sequencia-botfactory.md](arq-diagrama-sequencia-botfactory.md)

**Quero configurar o ambiente**
1. [guia-setup-inicial.md](guia-setup-inicial.md)
2. [ref-config-application-properties.md](ref-config-application-properties.md)
3. [ref-comandos-rapidos.md](ref-comandos-rapidos.md)

**Quero depurar Vision / screenshot**
1. [guia-vision-api-templates.md](guia-vision-api-templates.md)
2. [guia-captura-screenshot.md](guia-captura-screenshot.md)
3. [guia-sistema-logs.md](guia-sistema-logs.md)

---

## Arquivo histórico

Documentos antigos em [`archive/`](archive/README.md) — fixes pontuais, POCs e refactorings já aplicados.

---

## Mapa de nomes antigos → novos

| Nome antigo | Nome novo |
|-------------|-----------|
| `SETUP.md` | `guia-setup-inicial.md` |
| `TASK-EXECUTION-GUIDE.md` | `guia-execucao-task-core.md` |
| `ARCHITECTURE.md` | `arq-visao-geral-bot.md` |
| `VISION-API.md` | `guia-vision-api-templates.md` |
| `FLOW-SYNC-S3.md` | `guia-sync-manifests-s3.md` |
| `QUICK-REFERENCE.md` | `ref-comandos-rapidos.md` |
| `APPLICATION-CONFIG.md` | `ref-config-application-properties.md` |
| … | Ver prefixos acima |

Scripts: [utils/scripts/bot/](../../utils/scripts/bot/)
