# Arquitetura do fluxo – Bot DDT

Este doc responde: (1) diferença entre desenvolver APIs e um app único; (2) por que o Orchestrator ainda é necessário; (3) se o formato segue boas práticas; e (4) diagrama de sequência atualizado com o código atual.

---

## 1. APIs vs um único programa (app)

Em **APIs** você costuma ter:
- Várias rotas/endpoints que **respondem a pedidos** (request/response).
- Pouca “memória” de estado entre requests (ou estado em DB/cache).
- Cada request pode ser tratado de forma **independente** (escala horizontal, stateless).

Num **app único** (como este bot Android):
- Há **um fluxo contínuo**: iniciar → loop infinito (validar rede → detectar tela → login → menu → batalha → repetir) até o usuário parar ou falha de rede.
- O **estado** importa: tela atual, permissões, serviço de captura ativo, etc.
- **Quem coordena** esse loop e a ordem dos passos não é “uma rota”, é um **orquestrador** que decide “agora faço login”, “agora espero”, “agora chamo o use case de menu”, etc.

Ou seja: no app, o **Orchestrator** é o “maestro” desse fluxo contínuo; em APIs, o “fluxo” costuma ser uma única operação por request.

---

## 2. O Orchestrator ainda é necessário?

**Sim.** Ele concentra a **lógica de controle do ciclo de vida** do bot:

| Sem Orchestrator | Com Orchestrator |
|------------------|------------------|
| O loop (rede → detectar tela → login → delay → repetir) teria que estar no **ViewModel** ou no **StartBotUseCase**. | O **Orchestrator** é o único dono do loop e das decisões “o que fazer nesta volta”. |
| ViewModel ou Use Case ficariam com duas responsabilidades: “iniciar bot” **e** “decidir o que fazer a cada ciclo”. | **StartBotUseCase** só: validar rede, abrir jogo, **chamar** `orchestrator.start()`. O “o quê” de cada ciclo fica no Orchestrator. |
| Adicionar novos fluxos (menu, batalha, etc.) exigiria mexer em ViewModel ou em um Use Case gigante. | Novos fluxos = novos métodos no Orchestrator (`executeMainMenuFlow()`, `executeBattleFlow()`) e um `when (screen)` maior; ViewModel e Use Cases continuam estáveis. |

Resumo: o **Orchestrator** é necessário como **único lugar** que sabe a ordem e as condições do ciclo (rede → detectar tela → qual fluxo executar → delay → repetir). Isso segue o princípio de responsabilidade única e facilita evoluir o bot (novas telas, novos fluxos).

---

## 3. Esse formato respeita boas práticas?

Sim, no contexto de um app Android com Clean Architecture leve:

- **BotFactory (DI manual):** um único ponto que monta o grafo de dependências e expõe só o `BotViewModel` para a UI. Evita acoplamento na Activity e facilita testes (no futuro você pode injetar mocks).
- **Orchestrator:** um único componente que orquestra o ciclo do bot; Use Cases fazem “uma coisa” (login, detect+click, etc.), o Orchestrator só decide “quando” chamar cada um.
- **Repositórios por interface (IScreenshotRepository, IVisionRepository, IClickRepository):** domínio não depende de implementação; trocar Vision API ou captura de tela não quebra o domínio.
- **Config em `app-{ENV}.properties` → BuildConfig:** config fora do código, por ambiente, sem defaults duplicados no build.
- **Use Cases com parâmetros explícitos (thresholds, delays):** regras de negócio e limites configuráveis ficam claros e testáveis.

Não é “Clean Architecture completa” (não há camada de entidades de domínio puras, nem Dagger/Hilt), mas é um desenho consistente, testável e fácil de estender.

---

## 4. Grafo do BotFactory (dependências criadas pelo Factory)

**Diagramas (grafo + sequência):** ver **[diagram-fluxo.md](diagram-fluxo.md)** — arquivo único de referência. Atualize-o quando alterar BotFactory, Orchestrator ou use cases. O grafo mostra **tudo o que o BotFactory instancia** e **quem depende de quem**; a seta A → B significa “BotFactory passa A como dependência de B” (B recebe A no construtor, ou B usa A internamente — e.g. VisionRepositoryImpl usa VisionDtoMapper; o Factory não injeta o mapper).


**Resumo do grafo:** BotFactory recebe `Context`, `FloatingLogWindow` e `onMainLog`. Cria a árvore de objetos (logging, VisionApiService, repositórios, validators, use cases, orchestrator, start/stop use cases) e retorna apenas **BotViewModel**. VisionDtoMapper não é instanciado nem injetado pelo Factory; VisionRepositoryImpl usa o mapper internamente para converter DTO → Entity.

---

## 5. Diagrama de sequência

O diagrama de sequência (inicialização, start do bot, loop do Orchestrator, Vision DTO→Entity) está em **[diagram-fluxo.md](diagram-fluxo.md)** (sec. 2).

---

## 5. Resumo
## 5. Resumo

- **APIs vs app:** no app, um fluxo contínuo e estado são centrais; quem coordena é o Orchestrator, não “uma rota por ação”.
- **Orchestrator:** necessário como único dono do ciclo (rede → detectar tela → executar fluxo adequado → delay → repetir) e para crescer com novos fluxos sem poluir ViewModel ou Use Cases.
- **Boas práticas:** Factory para DI, interfaces de repositório, DTO → Mapper → Entity na Vision, config em `app-{ENV}.properties`, Use Cases com parâmetros claros.
- **Grafo do BotFactory (sec. 4):** mostra tudo o que o Factory instancia e as dependências entre componentes (quem recebe quem).
- **Diagrama de sequência (sec. 5):** fluxo de inicialização, start do bot e loop do Orchestrator; no fluxo Vision, aparece **LensResponse (DTO)** → **VisionDtoMapper.toScreenMatch()** → **ScreenMatch (entity)**.

Para alterar no futuro: edite **[diagram-fluxo.md](diagram-fluxo.md)** em sintonia com `BotFactory`, `AutomationOrchestrator`, `FlowLoginUseCase`, `ScreenValidator`, `VisionRepositoryImpl` e `VisionDtoMapper`.

**Task do Core e plano `flow_step` / `flow_step_image`:** ver **[ORCHESTRATOR-TASK-CORE-FLOW.md](ORCHESTRATOR-TASK-CORE-FLOW.md)** (diagramas, lacunas de API e plano de implementação no `AutomationOrchestrator`).

---

## 7. Leitura a partir dos dois fluxos: o projeto está bem encaminhado?

Com base no **grafo** (estrutura) e no **diagrama de sequência** (comportamento), o desenho está alinhado a padrões reconhecidos:

- **Separação de camadas:** API (VisionApiService, DTOs) → Data (repositórios, mapper) → Domain (validators, use cases, orchestrator) → Presentation (ViewModel). O grafo e a sequência mostram essa fronteira; a UI só conhece o ViewModel.
- **Inversão de dependência:** O grafo mostra dependências apontando para dentro do domínio (repos implementam interfaces; o Orchestrator e os use cases dependem de abstrações). A sequência confirma: o domínio orquestra chamadas a repositórios e não conhece DTOs.
- **Responsabilidade única:** O Orchestrator só decide “o que fazer no ciclo”; os use cases executam um fluxo (login, detect+click); repositórios acessam fontes (API, screenshot, click); o mapper só converte DTO → Entity. Cada papel aparece claro nos dois fluxos.
- **DTO ↔ Entity:** A sequência explicita API retornando DTO, mapper produzindo entidade, domínio recebendo só entidade. O grafo coloca o mapper na camada data, entre API e domínio. Padrão adequado para múltiplas APIs.
- **Composição no Factory:** O grafo mostra uma única entrada (createBotViewModel) e uma única saída (BotViewModel), com a árvore de dependências montada no meio. Padrão de composição raiz / DI manual, sem serviços globais.

O que ainda não aparece nos desenhos (menu principal, batalha) está indicado como TODO e se encaixa no mesmo padrão: novos use cases e novos métodos no Orchestrator, sem mudar a estrutura do grafo.

**Conclusão:** Com base nos dois fluxos, o projeto está bem encaminhado e aderente a padrões de separação de camadas, inversão de dependência, uso de DTO/Entity e orquestração por um único componente (Orchestrator), com o Factory como ponto único de montagem do grafo.
