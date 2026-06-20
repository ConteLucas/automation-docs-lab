# Backup v4 – Clean Code e Código Morto

## Backup v4

- **Arquivo:** `automation-learn/backups/automation-bot-ddt-backup-v4.zip`
- **Conteúdo:** `app/src/main/java`, `app/src/main/res`, `app/src/main/assets`, `app/build.gradle.kts`
- **Observação:** O projeto não está em um repositório git neste workspace; o backup foi feito em zip. Se você usar git em outro lugar, pode criar a tag manualmente: `git tag backup-v4`

---

## ScreenClicker está em uso

**ScreenClicker não é código morto.** Ele é usado em dois pontos:

| Quem usa | Como |
|----------|------|
| **ClickRepositoryImpl** | Cria `ScreenClicker(context)` e chama `screenClicker.clickAt(x, y)` para disparar o clique. |
| **BotAccessibilityService** | Chama `ScreenClicker.setAccessibilityService(this)` no `onServiceConnected()` e `setAccessibilityService(null)` no `onDestroy()`, para que o ScreenClicker use o serviço de acessibilidade na hora do clique. |

O fluxo real é: **DetectAndClickUseCase** → **IClickRepository.clickAt(centerX, centerY)** → **ClickRepositoryImpl** → **ScreenClicker.clickAt(x, y)**. Ou seja, **ScreenClicker** e **ClickRepositoryImpl** fazem parte do fluxo de clique e devem ser mantidos.

O que **não** é usado é só:

- O **enum GameCoordinate** (e os valores `LOGIN_BTN_ENTER`, `LOGIN_BTN_CANCEL`).
- O **overload** `ScreenClicker.click(coordinate: GameCoordinate, onLog)`.

Ninguém chama `screenClicker.click(algumGameCoordinate)`. Só se chama `screenClicker.clickAt(x, y)`. Por isso dizemos que o **método** `click(GameCoordinate)` e o **tipo** GameCoordinate são código morto; a **classe ScreenClicker** e o método **clickAt** continuam em uso.

---

## Por que ConfigRepository, DeviceInfo e GameCoordinate são “código morto”

“Código morto” = código que **nunca é executado** porque nenhum outro arquivo o chama (nem por referência direta nem por reflexão/configuração que o projeto use).

### 1. ConfigRepository.kt

- **O que é:** Classe que guarda em SharedPreferences: URL do Vision API, URL do Core API, API key, package do jogo, device ID.
- **Por que é morto:** Nenhum outro arquivo do projeto faz `import ...ConfigRepository` nem instancia `ConfigRepository` nem chama métodos como `getVisionApiUrl()` ou `saveVisionApiUrl()`. A URL do Vision API hoje está fixa em **NetworkValidator** e **BotFactory** (ex.: `"http://10.0.2.2:8000/health"`). Ou seja, a classe existe, mas **nenhuma chamada** a usa.
- **Conclusão:** Ou você passa a usar ConfigRepository (injetar no BotFactory/NetworkValidator e ler as URLs daí), ou pode remover a classe sem quebrar nada.

### 2. DeviceInfo.kt

- **O que é:** Object com funções como `getDeviceName()`, `getAndroidVersion()`, `getDetailedInfo()` (para log/diagnóstico de dispositivo/emulador).
- **Por que é morto:** Nenhum outro arquivo faz `import ...DeviceInfo` nem chama `DeviceInfo.getDeviceName()` (ou qualquer outro método). O object está definido, mas **nunca é referenciado**.
- **Conclusão:** Se não for usar em logs ou telas de diagnóstico, pode remover; senão, basta passar a chamar de algum lugar (ex.: ao abrir a tela de log ou ao iniciar o bot).

### 3. GameCoordinate.kt e ScreenClicker.click(GameCoordinate)

- **O que é:** Enum com coordenadas fixas (ex.: `LOGIN_BTN_ENTER`, `LOGIN_BTN_CANCEL`) e o método `ScreenClicker.click(coordinate: GameCoordinate, onLog)` que clica em `(coordinate.x, coordinate.y)`.
- **Por que é morto:**  
  - Ninguém chama `ScreenClicker.click(algumGameCoordinate)`.  
  - O único uso de **GameCoordinate** no projeto é como **tipo do parâmetro** desse método.  
  - O fluxo real de clique usa sempre **coordenadas (x, y)** vindas do **ScreenMatch** (Vision API) e chama só **clickAt(centerX, centerY)**.  
  Ou seja, o enum e esse overload **nunca são usados**.
- **Conclusão:** Pode remover o enum **GameCoordinate.kt** e o método **ScreenClicker.click(GameCoordinate, ...)** (e o `import` de GameCoordinate em ScreenClicker). O restante do **ScreenClicker** (incluindo **clickAt** e a integração com **BotAccessibilityService** e **ClickRepositoryImpl**) continua em uso e não deve ser removido.

---

## Resumo: o que remover (se quiser limpar)

| Item | Ação | ScreenClicker / ClickRepositoryImpl |
|------|------|-------------------------------------|
| **ConfigRepository.kt** | Remover classe (ou passar a usá-la). | Não afeta. |
| **DeviceInfo.kt** | Remover object (ou passar a usá-lo). | Não afeta. |
| **GameCoordinate.kt** | Remover enum. | Não afeta. |
| **ScreenClicker.click(GameCoordinate, …)** | Remover só esse método (e o import de GameCoordinate). | **ScreenClicker** e **clickAt** continuam sendo usados por **BotAccessibilityService** e **ClickRepositoryImpl**. |

---

## Pontos de melhoria (Clean Code) – varredura no código

Sugestões objetivas para melhorar legibilidade e manutenção, sem mudar comportamento.

1. **Magic numbers**
   - Ex.: `0.5` em `template.width < screenshot.width * 0.5` (ScreenValidator, AutomationOrchestrator). Extrair para constante nomeada (ex.: `SMALL_TEMPLATE_WIDTH_RATIO`) em **AppConstants** ou no próprio uso.
   - Ex.: `25` segundos de timeout no screenshot (BotAccessibilityService). Já existe constante em alguns lugares; unificar em **AppConstants** se fizer sentido.

2. **Métodos longos**
   - **MainActivity**: muitos callbacks e lógica de permissão/MediaProjection na Activity. Extrair para um **PermissionHelper** ou **MediaProjectionHelper** e deixar a Activity só orquestrando.
   - **FlowLoginUseCase.execute()**: vários passos; já está dividido em métodos privados (executeClickLogin, etc.), que é bom. Se algum deles crescer muito, considerar extrair mais um nível (ex.: “wait for action bar” em um método só).

3. **Duplicação**
   - Cálculo de “centro do match” (`result.x + result.width/2`, `result.y + result.height/2`) aparece em **DetectAndClickUseCase**. Pode virar extensão em **ScreenMatch** (ex.: `screenMatch.centerX`, `screenMatch.centerY`) ou função de utilidade, para um único lugar de definição.

4. **Nomes e responsabilidades**
   - **ScreenValidator** usa “small template = lens, large = match” de forma implícita. Um comentário breve ou constante nomeada (ex.: “lens vs full-screen match”) deixa a intenção mais clara.
   - **BotFactory** está enxuto após a limpeza; manter uma única responsabilidade (montar o grafo de dependências) e evitar colocar lógica de negócio ali.

5. **Tratamento de erros**
   - Em vários `catch` só se faz log e retorno (ou `Result.failure`). Está aceitável; se no futuro quiser padronizar (ex.: sempre log + métrica ou sempre mesmo formato de erro), dá para extrair um helper (ex.: “logAndReturnFailure”) sem reintroduzir o helper genérico que você preferiu não usar.

6. **Testes**
   - **ConfigRepository** e **DeviceInfo** não têm testes e não são usados. Se forem removidos, não há impacto em cobertura de código usado. Se forem mantidos para uso futuro, vale adicionar testes na hora em que forem integrados.

---

## Checklist pós-backup v4

- [ ] Backup v4 salvo em `automation-learn/backups/automation-bot-ddt-backup-v4.zip`
- [ ] Entendido: **ScreenClicker** e **ClickRepositoryImpl** ficam; só **GameCoordinate** e **ScreenClicker.click(GameCoordinate)** são mortos
- [ ] Decidir: remover ou passar a usar **ConfigRepository** e **DeviceInfo**
- [ ] Se limpar código morto: remover **GameCoordinate.kt** e o método **ScreenClicker.click(GameCoordinate, …)** (e import)
- [ ] (Opcional) Aplicar melhorias de clean code acima onde fizer sentido para você
