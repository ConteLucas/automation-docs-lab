# DTO e mapeamento para entidades de domínio

Convenção usada no projeto para manter a camada de API (DTOs) separada do domínio (entidades) e facilitar a inclusão de novas APIs.

---

## 1. Conceitos

| Camada   | Nome usado no projeto | Onde fica | Papel |
|----------|------------------------|-----------|--------|
| **API**  | **DTO** (Data Transfer Object) | `api/dto/request`, `api/dto/response` | Formato do contrato da API (JSON ↔ Kotlin). Pode mudar quando o backend mudar. |
| **Domínio** | **Entity** / **Model** | `domain/models` | Regras e tipos do negócio. Estável; a app não depende do formato exato do JSON. |
| **Mapeamento** | **Mapper** (DTO → Entity) | `data/mapper` | Converte DTO em entidade. Fica na camada **data** (que conhece API e domínio). |

- **DTO**: espelha o que a API envia/recebe (nomes de campos, tipos, opcionais). Pode ter `@SerializedName`, valores default, etc.
- **Entity**: o que o domínio usa (ScreenMatch, OcrRegion, etc.). Sem anotações de serialização; pode ter enums e tipos de domínio.
- **Mapper**: funções ou classes que fazem `LensResponse` → `ScreenMatch`, etc. Repositório chama o mapper em vez de montar a entidade na mão.

---

## 2. Estrutura atual

```
app/src/main/java/com/automation/bot/
├── api/
│   ├── dto/
│   │   ├── request/          # DTOs de requisição (LensRequest, MatchRequest, OcrRequest, …)
│   │   └── response/         # DTOs de resposta (LensResponse, HealthResponse, OcrResponse, …)
│   ├── VisionApi.kt          # Interface Retrofit (usa DTOs)
│   └── VisionApiService.kt   # Serviço que chama a API e retorna DTOs
├── domain/
│   └── models/               # Entidades de domínio (ScreenMatch, OcrRegion, …)
└── data/
    ├── mapper/
    │   └── VisionDtoMapper.kt   # LensResponse → ScreenMatch, fallback toNoMatch()
    └── repository/
        └── VisionRepositoryImpl.kt  # Chama VisionApiService (DTOs) e usa VisionDtoMapper → retorna Entity
```

- **api**: só conhece DTOs e contrato HTTP; não depende de `domain`.
- **domain**: só conhece entidades e regras; não conhece DTOs nem Retrofit.
- **data**: conhece api + domain; orquestra chamadas e usa os mappers para devolver entidades ao domínio.

---

## 3. Padrão ao adicionar uma nova API

1. **Criar DTOs da API**
   - Em `api/dto/request/` e `api/dto/response/` (ou subpastas por API, ex.: `api/dto/response/game/`).
   - Nomes que deixem claro que são do contrato (ex.: `GameServerStatusResponse`, `InventoryItemDto`).

2. **Definir entidades de domínio (se fizer sentido)**
   - Em `domain/models/` (ou `domain/entities/` se quiser separar).
   - Só o que a aplicação precisa para regras e fluxos; não precisa espelhar todos os campos do JSON.

3. **Criar o mapper na camada data**
   - Em `data/mapper/`, por API ou por grupo (ex.: `VisionDtoMapper`, `GameApiDtoMapper`).
   - Métodos estáticos ou object: `toScreenMatch(dto, threshold)`, `toDomainEntity(dto)`, etc.
   - Mapper **não** chama rede; só converte DTO → Entity (e, se precisar no futuro, Entity → DTO para envio).

4. **Repositório usa API + mapper**
   - O repositório chama o serviço da API (que retorna DTOs) e usa o mapper para obter a entidade e retorná-la ao domínio.
   - Exemplo: `val dto = someApiService.getSomething(); return SomeApiDtoMapper.toEntity(dto)`.

5. **Manter domínio estável**
   - Se a API mudar o JSON, altere o DTO e o mapper; o domínio (e os use cases) podem continuar iguais se a entidade não precisar mudar.

---

## 4. Exemplo: Vision API (já adotado)

- **DTO**: `LensResponse` (found, confidence, x, y, width, height, error).
- **Entity**: `ScreenMatch` (isMatch, confidence, expectedScreen, x, y, width, height).
- **Mapper**: `VisionDtoMapper.toScreenMatch(dto, threshold)` e `VisionDtoMapper.toNoMatch()`.
- **Repositório**: `VisionRepositoryImpl` chama `visionApiService.lens(...)` / `match(...)`, recebe `LensResponse`, usa `VisionDtoMapper.toScreenMatch(response, threshold)` e retorna `ScreenMatch` para o domínio.

Assim, o domínio nunca vê `LensResponse`; só trabalha com `ScreenMatch`.

---

## 5. Nomenclatura sugerida

- **DTO**: sufixo opcional nos nomes (ex.: `LensResponse` já indica resposta da API; para várias APIs pode usar `XxxResponseDto` ou manter em pastas `api/dto/response/`).
- **Entity**: pode manter em `domain/models` com nomes de negócio (ScreenMatch, OcrRegion); se criar pasta `domain/entities`, use o mesmo critério de nome estável.
- **Mapper**: `XxxDtoMapper` ou `XxxApiMapper`, em `data/mapper/`, com métodos como `toEntity(dto)` ou `toScreenMatch(dto, threshold)`.

Com isso, fica claro: **API = DTO**, **domínio = Entity**, **data = mapeamento DTO → Entity**, e novas APIs seguem o mesmo padrão.

---

## 6. Sugestões de melhoria (opcionais)

- **Outras respostas Vision:** Se no futuro o endpoint `match` passar a devolver um formato diferente do `lens`, crie um DTO específico (ex.: `MatchResponse`) e um método no mapper, ex.: `toScreenMatch(matchResponse: MatchResponse, threshold: Float)`.
- **OCR:** Se o domínio precisar de um tipo rico para resultado de OCR (além de `String`), crie uma entidade em `domain/models` e um `VisionDtoMapper.toOcrResult(OcrResponse)` (ou um mapper dedicado em `data/mapper`).
- **Novas APIs (ex.: Game API, Auth API):** Repetir o padrão: `api/dto/request|response` (ou subpastas por API), `data/mapper/XxxDtoMapper`, repositório que chama API e usa mapper antes de retornar ao domínio.
- **Testes:** Testar o mapper isoladamente (DTO → Entity) garante que mudanças no contrato da API são tratadas em um único lugar.
