# Árvore de classes – app automation-bot-ddt

Cada entrada lista a classe, uma descrição breve e, quando relevante, **acoplamento alto** ou **múltiplas responsabilidades** (possível violação de Clean Code / SRP).

---

## Raiz do app

```
com.automation.bot
├── BotApplication          # Ponto de entrada; planta Timber.DebugTree em DEBUG. OK.
├── BuildConfig             # Constantes de build (DEBUG). ⚠️ Pode conflitar com o gerado pelo Gradle.
└── di/
    └── BotFactory          # Monta o grafo de dependências (ViewModel, use cases, repositórios).
                            # Uma única responsabilidade: DI. OK.
```

---

## Camada de apresentação (UI + ViewModel)

```
presentation/
└── viewmodel/
    └── BotViewModel        # Estado do bot (IDLE/RUNNING/PAUSED), start/pause/stop, LogcatMonitor,
                            # tratamento de NetworkException, log em arquivo e float.
                            # ⚠️ Instancia LogcatMonitor internamente (poderia ser injetado).
                            # Vários colaboradores; orquestração é uma responsabilidade. OK com ressalva.

ui/
├── MainActivity            # Activity principal: MediaProjection, permissões, botões, lista de log,
                            # filtro, criação do ViewModel e da FloatingLogWindow.
                            # ⚠️ Múltiplas responsabilidades: lifecycle da Activity + MediaProjection +
                            #    permissões (overlay, storage, a11y) + UI de log + filtro + callbacks.
                            # ⚠️ Acoplamento: conhece BotFactory, BotViewModel, FloatingLogWindow,
                            #    MediaProjectionService, MediaProjectionCapture, Settings, Intent.
                            # Sugestão: extrair PermissionHelper e MediaProjectionHelper.

├── FloatingLogWindow       # Janela flutuante (colapsada/expandida): ícone arrastável, logs, conta,
                            # nível, servidor, runtime, filtro, botões play/pause/fechar.
                            # ⚠️ Classe longa (~600 linhas): layout, estado, filtro, callbacks, WindowManager.
                            # Sugestão: separar FloatingLogState e talvez FloatingLogView binding.

└── ClickEffectOverlay      # Overlay visual de “clique” (círculo) na coordenada clicada.
                            # Uma responsabilidade. OK.
```

---

## Camada de domínio

### Use cases

```
domain/usecases/
├── flow/FlowLoginUseCase   # Fluxo de login: OPÇÃO → formulário → user/senha → botão login →
                            # pós-login (action_bar_root, OCR servidor, Enter game ou Switch account).
                            # Depende de IInputHelper (injetado); domínio desacoplado do Android. OK.

├── DetectAndClickUseCase  # Validar tela (template), obter centro, clicar, revalidar.
                            # Depende: ScreenValidator, IClickRepository. Uma responsabilidade. OK.

├── ScreenValidator         # Valida se a tela atual corresponde a um GameScreen (template + Vision).
                            # Inclui regra "template pequeno = lens, grande = match" (0.5 * width).
                            # ⚠️ Regra de negócio dentro do validador; poderia ser estratégia. OK com ressalva.

├── StartBotUseCase        # Valida rede, lança jogo se necessário, inicia Orchestrator.
                            # Depende: AppLauncher, AutomationOrchestrator, NetworkValidator. OK.

├── StopBotUseCase         # Para o bot e opcionalmente força parada do app (DDT).
                            # Depende: AppLauncher, callback onLog. OK.

└── NetworkValidator        # Verifica internet (ConnectivityManager) e opcionalmente saúde da Vision API.
                             # Depende: Context, visionApiUrl. Uma responsabilidade. OK.
```

### Orchestrator

```
domain/orchestrator/
└── AutomationOrchestrator  # Loop infinito: detectar tela → se LOGIN_SCREEN executa login → senão espera.
                             # Delega detecção a ScreenValidator.detectCurrentScreen(); sem duplicação. OK.
```

### Repositórios (interfaces)

```
domain/repository/
├── IClickRepository        # Contrato: clickAt(x, y). OK.
├── IScreenshotRepository   # Contrato: takeScreenshot(), loadTemplate(path), isInitialized(). OK.
└── IVisionRepository       # Contrato: detectElement, compareScreens, extractText, extractNumber. OK.
```

### Modelos de domínio

```
domain/models/
├── OcrRegion               # Região para OCR (x, y, width, height). Data class. OK.
└── ScreenMatch             # Resultado de match: isMatch, confidence, x, y, width, height, expectedScreen. OK.
```

### Exceções

```
domain/exceptions/
├── ClickValidationException  # Falha ao validar/clicar (element, attempts, message). OK.
└── NetworkException          # Falha de rede/API. OK.
```

### Enums

```
domain/enums/
├── GameScreen              # Telas conhecidas (UNKNOWN, LOGIN_*, BUTTON_ENTER_GAME, SWITCH_ACCOUNT)
                            # com templatePath e description. OK.
├── LogCategory             # Categoria do log (FLOW, VISION, etc.). OK.
└── LogLevel                # Nível (DEBUG, INFO, WARNING, ERROR, SUCCESS). OK.
```

### Input (abstração de acessibilidade)

```
domain/input/
└── IInputHelper            # Contrato: isAvailable, fillTextField, clickButtonByResourceId,
                            # pressEnter, hasNodeWithResourceId. Domínio não depende de Android. OK.
```

### Constantes

```
domain/constants/
└── AppConstants            # Constantes globais: pacote, timing, Vision, login, OCR, dimensões.
                            # ⚠️ Muitos grupos (pacote, delays, retry, credenciais, OCR, região) no mesmo
                            #    objeto; várias razões para mudar. Poderia separar em LoginConstants,
                            #    VisionConstants, etc. OK com ressalva.
```

---

## Camada de dados (implementações)

```
data/
data/repository/
├── ClickRepositoryImpl     # Implementa IClickRepository usando ScreenClicker; loga resultado.
                             # Depende: Context, ScreenClicker. Uma responsabilidade. OK.

├── ScreenshotRepositoryImpl # Implementa IScreenshotRepository: screenshot via ScreenCapture,
                              # templates via TemplateManager. OK.

└── VisionRepositoryImpl    # Implementa IVisionRepository: chama VisionApiService, converte para ScreenMatch.
                             # ⚠️ Contém retry (repeat 2x), tratamento por tipo de exceção (Http, timeout,
                             #    host) e logging. Repositório com política de resiliência; poderia extrair
                             #    retry/fallback. OK com ressalva.
```

---

## Automação (Android: Accessibility, MediaProjection, etc.)

```
automation/
├── InputHelperAdapter         # Implementa IInputHelper delegando a AccessibilityInputHelper.getInstance(). OK.
├── BotAccessibilityService   # AccessibilityService: conecta ScreenClicker, AccessibilityInputHelper,
                              # screenshot; expõe captureScreenshot() e takeScreenshot().
                              # ⚠️ Duas responsabilidades: serviço de acessibilidade + captura de tela.
                              # Sugestão: extrair ScreenshotCaptureDelegate ou manter documentado.

├── ScreenClicker             # Dispara clique em (x,y) via GestureDescription do AccessibilityService;
                              # opcionalmente mostra ClickEffectOverlay.
                              # Depende: BotAccessibilityService (companion), ClickEffectOverlay, Context.
                              # Uma responsabilidade. OK.

├── AccessibilityInputHelper   # Preenche campos por hint, clica botão por resource-id, ENTER,
                               # hasNodeWithResourceId; dump de nós para debug.
                               # ⚠️ Várias utilidades: input, click em botão, tecla, detecção de nó, debug.
                               # Sugestão: manter mas documentar; ou separar NodeFinder vs InputActions.

├── MediaProjectionService     # Foreground service que recebe resultCode/data do MediaProjection e
                               # inicializa MediaProjectionCapture. Uma responsabilidade. OK.

├── MediaProjectionCapture     # Singleton: initialize(resultCode, data), VirtualDisplay, ImageReader,
                               # takeScreenshot(), release(). Gerencia ciclo de vida do MediaProjection.
                               # Responsabilidade concentrada em captura. OK.

├── ScreenCapture              # Encapsula MediaProjectionCapture: takeScreenshot(), saveBitmap().
                                # Depende: Context, MediaProjectionCapture. OK.

└── AppLauncher                 # Lança app por package, forceStop, isInstalled, isAppRunning.
                                 # Depende: Context. OK.
```

---

## API (Vision)

```
api/
├── VisionApi                 # Interface Retrofit: lens, match, extractText, extractNumber, health. OK.
├── VisionApiService          # Configura OkHttp/Retrofit (timeouts, pool), converte Bitmap→Base64, chama API.
                              # ⚠️ Configuração HTTP + encoding + chamadas em um só lugar; poderia separar
                              #    cliente (Retrofit) de conversão (BitmapEncoder). OK com ressalva.

api/dto/request/
├── LensRequest               # DTO: objectImage, screenImage, threshold. OK.
├── MatchRequest              # DTO: idem. OK.
└── OcrRequest                # DTO: image, region. OK.

api/dto/response/
├── LensResponse              # found, confidence, x, y, width, height, error. OK.
├── OcrResponse               # text. OK.
├── NumberResponse            # number. OK.
└── HealthResponse            # status. OK.

api/models/
└── Region                    # x, y, width, height (para API). OK.
```

---

## Templates e utilitários

```
templates/
└── TemplateManager           # Carrega template de assets por path (InputStream, bytes, Bitmap). OK.

utils/
├── BotLogTree                # Timber.Tree que encaminha log para callback (UI/arquivo) com formato e dedup. OK.
├── LoggerExtensions          # Função log(LogCategory, LogLevel) { } → Timber. OK.
├── LogFileManager            # Append em arquivo de log, startNewLog. OK.
└── LogcatMonitor             # Processo logcat do jogo (package), envia linhas para Timber. OK.
```

---

## Resumo – possíveis desvios de Clean Code

**Classes em situação adequada (uma responsabilidade, acoplamento coerente):** BotApplication, BotFactory, ClickEffectOverlay, DetectAndClickUseCase, StartBotUseCase, StopBotUseCase, NetworkValidator; interfaces IClickRepository, IScreenshotRepository, IVisionRepository; ClickRepositoryImpl, ScreenshotRepositoryImpl, ScreenClicker; MediaProjectionService, MediaProjectionCapture, ScreenCapture, AppLauncher; VisionApi, TemplateManager; BotLogTree, LoggerExtensions, LogFileManager, LogcatMonitor; OcrRegion, ScreenMatch; exceções e enums de domínio; DTOs e Region da API.

**Problemas (múltiplas responsabilidades / acoplamento / código morto):**

| Classe | Problema | Sugestão |
|--------|----------|----------|
| **MainActivity** | Múltiplas responsabilidades (Activity + MediaProjection + permissões + log + filtro). | Extrair PermissionHelper, MediaProjectionHelper; manter Activity mais fina. |
| **FloatingLogWindow** | Classe muito longa; layout + estado + filtro + WindowManager. | Extrair estado (FloatingLogState) ou quebrar em sub-componentes. |
| **BotViewModel** | Instancia LogcatMonitor; muitos colaboradores. | Injetar LogcatMonitor. |
| **BotAccessibilityService** | Serviço de acessibilidade + responsabilidade de screenshot. | Documentar ou extrair “screenshot delegate”. |
| **AccessibilityInputHelper** | Várias utilidades: input, click em botão, ENTER, hasNodeWithResourceId, dump. | Documentar ou separar NodeFinder vs InputActions. |
| ~~FlowLoginUseCase~~ | ~~Context~~ | **Corrigido:** passa a depender de IInputHelper (injetado). |
| **ScreenValidator** | Regra lens vs match (0.5 * width) dentro do validador. | Extrair estratégia ou constante (opcional). |
| ~~AutomationOrchestrator~~ | ~~Duplicação detectCurrentScreen~~ | **Corrigido:** delega a ScreenValidator.detectCurrentScreen(). |
| **VisionRepositoryImpl** | Retry, tratamento de exceção por tipo e logging no repositório. | Extrair retry/fallback ou aceitar como resiliência. |
| **VisionApiService** | Configuração OkHttp/Retrofit + Bitmap→Base64 + chamadas. | Opcional: separar cliente de encoder. |
| **AppConstants** | Muitos grupos (pacote, timing, login, OCR) no mesmo objeto. | Opcional: separar LoginConstants, VisionConstants. |
| **BuildConfig** | Arquivo manual pode conflitar com o gerado pelo Gradle. | Usar só BuildConfig gerado ou documentar. |
| ~~ConfigRepository~~ | ~~Código morto~~ | **Removido.** |
| ~~DeviceInfo~~ | ~~Código morto~~ | **Removido.** |

---

## Legenda da árvore

- **OK** = responsabilidade única ou contrato claro; acoplamento coerente com a camada.
- **OK com ressalva** = pequeno desvio (ex.: dependência injetável, regra extraível); aceitável.
- **⚠️** = múltiplas responsabilidades ou acoplamento alto; vale revisão ou refatoração.
- **Código morto** = não referenciado no fluxo atual; pode ser removido ou integrado.
