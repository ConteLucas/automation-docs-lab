# R00 — Fundação da plataforma

**Período:** 2025 — início 2026  
**Status:** concluída  
**Ambiente:** local / desenvolvimento

---

## Objetivo

Estabelecer o núcleo da plataforma DDT: API de orquestração, bot Android, painel web CRM, modelo relacional de pedidos/tasks/flows e integração com visão computacional.

---

## Entregas

- **automation-core-lab** — Spring Boot 3, hexagonal, REST, JPA/Hibernate, PostgreSQL
- **automation-bot-lab** — APK Kotlin, UIAutomator2, claim de tasks
- **automation-web-lab** — React, CRM (pedidos, clientes, devices, flows)
- **automation-vision-lab** — FastAPI para OCR/match
- **automation-db-lab** — DDL de referência, seeds, diagramas
- Modelo **1:N** `game_account` ↔ `game_details_account` (login único por conta)
- 65 servidores em `server`, agrupados em `range_server`
- RBAC inicial: ADM, DEV, MANAGER, SELLER

---

## Arquitetura (snapshot)

Ver [ARCHITECTURE.md](ARCHITECTURE.md).  
Estado **atual** do ecossistema: [../../ARCHITECTURE.md](../../ARCHITECTURE.md).

---

## Banco de dados

Tabelas núcleo introduzidas nesta fase: ver [DATABASE.md](DATABASE.md) e definição completa em [CORE-DATABASE-TABLES.md](../../db/docs/CORE-DATABASE-TABLES.md).

---

## Próximo passo

[R01 — Monorepo labs](../r01-monorepo-labs/README.md): reorganizar repositórios e documentação centralizada.
