# Template — nova release

Copie esta pasta para `releases/rNN-nome-curto/` e preencha os arquivos.

## Checklist

- [ ] `README.md` — resumo executivo (1 página)
- [ ] `CHANGELOG.md` — lista de mudanças (features, fixes, breaking)
- [ ] `ARCHITECTURE.md` — diagramas **como estavam ao fim desta release** (não precisa duplicar tudo; pode ser delta + link para doc global)
- [ ] `DATABASE.md` — tabelas/colunas novas ou alteradas (referenciar `db/ARCHITECTURE.md` atualizado)
- [ ] Atualizar [INDEX.md](INDEX.md) — linha na tabela e no timeline
- [ ] Atualizar [ARCHITECTURE.md](../ARCHITECTURE.md) e [db/ARCHITECTURE.md](../db/ARCHITECTURE.md) se a release mudou o desenho global

---

## README.md (modelo)

```markdown
# RNN — Título da release

**Período:** YYYY-MM  
**Status:** concluída | em andamento  
**Ambiente:** local | lab AWS | produção

## Objetivo

Uma frase sobre o porquê desta release.

## Entregas

- Item 1
- Item 2

## Arquitetura

Ver [ARCHITECTURE.md](ARCHITECTURE.md) desta release.  
Arquitetura **atual** (última release): [../../ARCHITECTURE.md](../../ARCHITECTURE.md).

## Banco de dados

Ver [DATABASE.md](DATABASE.md).

## Operação / deploy

Links para runbooks em infra/docs/.

## Próximo passo

O que a release seguinte deve assumir.
```

---

## CHANGELOG.md (modelo)

```markdown
# Changelog — RNN

## Added
- ...

## Changed
- ...

## Fixed
- ...

## Database
- ...

## Breaking / migração
- ...
```
