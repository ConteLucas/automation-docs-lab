# automation-vision-ocr

Serviço **OCR e visão** (template matching, lens) para o bot Android e ferramentas de debug. FastAPI + OpenCV + Tesseract.

**Índice completo:** [INDEX.md](INDEX.md)

## Como iniciar

### Stack completa (recomendado)

Na raiz do monorepo:

```bash
./bootstrap.sh
```

Vision OCR em http://localhost:8000 · health: http://localhost:8000/health · docs: http://localhost:8000/docs

### Só este serviço (Docker Compose)

```bash
docker compose up -d --build vision
```

### Local (sem Docker)

```bash
cd automation-vision-ocr
./scripts/setup.sh          # venv + dependências
source venv/bin/activate
python src/main.py          # http://localhost:8000
```

Ou via script Colima: `./scripts/start-vision-api.sh` (build imagem `ddt-vision-api`).

## Integração

| Cliente | URL típica |
|---------|------------|
| Bot (emulador) | `http://10.0.2.2:8000` |
| Host / Mac | `http://localhost:8000` |
| Container `automation-vision` | porta 8000 na rede Docker |

Configure no bot: `VISION_API_BASE_URL` em `application.properties`.

## Estrutura

```
automation-vision-ocr/
  src/main.py           # FastAPI app
  src/api/              # vision_routes, ocr_routes
  src/services/         # vision_service, ocr_service
  scripts/              # setup, start/stop helpers
  Dockerfile            # imagem usada pelo docker-compose (serviço `vision`)
```

## Documentação

- Endpoints e exemplos: [bot/guia-vision-api-templates.md](../bot/guia-vision-api-templates.md)
- Scripts auxiliares: [scripts/README.md](scripts/README.md)

## Nome do repositório

Anteriormente `automation-vision-ddt`. O nome **automation-vision-ocr** reflete o foco em OCR/visão; o container Docker continua `automation-vision` (serviço `vision` no `docker-compose.yml`).
