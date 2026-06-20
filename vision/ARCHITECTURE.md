# automation-vision-lab — Arquitetura

Serviço de **OCR e visão computacional** da plataforma DDT. Recebe screenshots e templates do bot Android, executa template matching (OpenCV) e OCR (Tesseract), e retorna coordenadas e texto para o bot automatizar a UI do jogo.

---

## Visão Macro

```mermaid
graph TB
    subgraph clients["Clientes"]
        BOT["Bot Android\nautomation-bot-lab"]
        DEBUG["Ferramentas de debug\n(MITM, scripts locais)"]
    end

    subgraph vision["automation-vision-lab (FastAPI :8000)"]
        direction TB

        subgraph api_layer["API Layer"]
            VR["vision_routes.py\nPOST /api/v1/vision/lens\nPOST /api/v1/vision/match"]
            OR["ocr_routes.py\nPOST /api/v1/ocr"]
            HLT["GET /health"]
        end

        subgraph services["Services Layer"]
            VS["vision_service.py\ntemplate matching via OpenCV"]
            OS["ocr_service.py\nOCR via Tesseract"]
        end

        subgraph utils["Utils"]
            IU["image_utils.py\ndecode Base64 → numpy array\npreprocessamento de imagem"]
            CFG["config.py\nvariáveis de ambiente\n(API key, thresholds, debug)"]
        end
    end

    BOT -->|POST Base64 images| VR & OR
    DEBUG -->|POST Base64 images| VR & OR
    VR --> VS
    OR --> OS
    VS & OS --> IU
    CFG --> VS & OS

    style vision fill:#d1fae5,stroke:#059669
    style api_layer fill:#dbeafe,stroke:#3b82f6
    style services fill:#ede9fe,stroke:#7c3aed
```

---

## Endpoints e Contratos

```mermaid
graph LR
    subgraph lens["POST /api/v1/vision/lens"]
        LI["Request:\n{template: base64,\n screenshot: base64,\n threshold: float}"]
        LO["Response:\n{found: bool,\n x: int, y: int,\n w: int, h: int,\n confidence: float}"]
        LI -->|OpenCV matchTemplate| LO
    end

    subgraph match["POST /api/v1/vision/match"]
        MI["Request:\n{template: base64,\n screenshot: base64,\n threshold: float}"]
        MO["Response:\n{found: bool,\n x: int, y: int,\n w: int, h: int,\n confidence: float}"]
        MI -->|OpenCV matchTemplate\n(escala grande)| MO
    end

    subgraph ocr["POST /api/v1/ocr"]
        OI["Request:\n{image: base64,\n region?: {x,y,w,h}}"]
        OO["Response:\n{text: string,\n confidence: float}"]
        OI -->|Tesseract OCR| OO
    end

    subgraph health["GET /health"]
        HO["Response: {status: ok}"]
    end
```

---

## Pipeline de Processamento

```mermaid
flowchart LR
    subgraph input["Input (Base64)"]
        TMPL["template.png\n(elemento a encontrar)"]
        SCRN["screenshot.png\n(tela atual do jogo)"]
    end

    subgraph decode["Decode"]
        B64["Base64 → bytes → numpy array\n(image_utils.py)"]
    end

    subgraph preprocess["Pré-processamento"]
        GRAY["Conversão Grayscale\n(OpenCV cvtColor)"]
        NORM["Normalização\n(equalizeHist)"]
    end

    subgraph compute["Computação"]
        MATCH["cv2.matchTemplate\n(TM_CCOEFF_NORMED)"]
        OCR_T["pytesseract.image_to_string\n(Tesseract v4+)"]
    end

    subgraph output["Output (JSON)"]
        RESULT["found, x, y, w, h, confidence\nou\ntext, confidence"]
    end

    TMPL & SCRN --> B64
    B64 --> GRAY --> NORM
    NORM --> MATCH & OCR_T
    MATCH & OCR_T --> RESULT
```

---

## Integração no Ecossistema

```mermaid
sequenceDiagram
    participant BOT as Bot (VisionRepositoryImpl)
    participant VA as Vision API :8000
    participant OCR as Tesseract
    participant CV as OpenCV

    Note over BOT,VA: Lens — encontrar elemento pequeno (botão, ícone)
    BOT->>VA: POST /api/v1/vision/lens\n{template: B64, screenshot: B64, threshold: 0.8}
    VA->>CV: matchTemplate (CCOEFF_NORMED)
    CV-->>VA: max_val, max_loc
    VA-->>BOT: {found: true, x:340, y:220, w:48, h:48, confidence:0.93}

    Note over BOT,VA: Match — comparar telas completas (verificar estado)
    BOT->>VA: POST /api/v1/vision/match\n{template: B64, screenshot: B64, threshold: 0.7}
    VA->>CV: matchTemplate (área maior)
    CV-->>VA: resultado
    VA-->>BOT: {found: bool, ...}

    Note over BOT,VA: OCR — extrair texto de região
    BOT->>VA: POST /api/v1/ocr\n{image: B64, region: {x,y,w,h}}
    VA->>OCR: pytesseract.image_to_string
    OCR-->>VA: texto extraído
    VA-->>BOT: {text: "Level 25", confidence: 0.87}
```

---

## Segurança em Produção

```mermaid
graph LR
    BOT -->|X-Vision-Api-Key header| GATE["API Key Guard\n(config.py: VISION_API_KEY)"]
    GATE -->|válida| SVC["vision_service / ocr_service"]
    GATE -->|inválida| ERR["HTTP 401 Unauthorized"]
```

Em `dev/local`: sem autenticação (key vazia = bypass).  
Em `prod`: variável `VISION_API_KEY` obrigatória (EC2 `.env.prod`).

---

## Estrutura de Arquivos

```
automation-vision-lab/
├── src/
│   ├── main.py              # FastAPI app + startup
│   ├── config.py            # Env vars (API_KEY, DEBUG, thresholds)
│   ├── image_utils.py       # Base64 decode, numpy conversion
│   ├── http_errors.py       # Exceções HTTP customizadas
│   ├── api/
│   │   ├── vision_routes.py # /lens + /match
│   │   └── ocr_routes.py    # /ocr
│   └── services/
│       ├── vision_service.py # OpenCV matchTemplate
│       └── ocr_service.py    # Tesseract wrapper
├── Dockerfile               # imagem da plataforma
├── requirements.txt         # dependências Python
├── application.properties   # config local referência
└── scripts/                 # setup.sh, start/stop helpers
```

---

## Tecnologias

| Item | Tecnologia |
|------|-----------|
| Linguagem | Python 3.10+ |
| Framework | FastAPI + Uvicorn |
| Visão | OpenCV (cv2) |
| OCR | Tesseract 4+ via pytesseract |
| Processamento | NumPy |
| Deploy | Docker (serviço `vision` no compose) |
| Porta | 8000 |

---

## Configuração por Ambiente

| Variável | Local | Prod |
|----------|-------|------|
| `VISION_API_KEY` | vazio (sem auth) | secret gerado pelo Terraform |
| `APP_ENVIRONMENT` | `local` | `prod` |
| URL no bot emulador | `http://10.0.2.2:8000` | `http://<EC2-IP>:8000` |
| URL no bot físico | `http://<IP-da-máquina>:8000` | `http://<EC2-IP>:8000` |
