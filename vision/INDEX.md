# Índice — Vision OCR (`automation-vision-lab`)

FastAPI — template matching, lens, OCR para o bot.

**Última atualização:** 2026-06-20

---

## Início rápido

| Documento | Conteúdo |
|-----------|----------|
| [README.md](README.md) | Como subir o serviço (Docker / local) |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Endpoints, OpenCV, Tesseract |
| [SCRIPTS.md](SCRIPTS.md) | Scripts auxiliares |

---

## Integração com o bot

| Documento | Conteúdo |
|-----------|----------|
| [../bot/guia-vision-api-templates.md](../bot/guia-vision-api-templates.md) | `/lens`, `/match`, OCR |
| [../bot/guia-captura-screenshot.md](../bot/guia-captura-screenshot.md) | Screenshot → Vision |

---

## Sync de templates (S3)

PNG de macro vão Core/S3 (não pelo Vision):

| Script | Repo |
|--------|------|
| `vision-lab/scripts/sync-metadata-images-to-s3.sh` | `automation-configs-lab` |
| `vision-lab/scripts/publish-metadata-local-s3.sh` | `automation-configs-lab` |

Layout: [../FLOW-SYNC-E-S3.md](../FLOW-SYNC-E-S3.md)

---

## URLs típicas

| Cliente | URL |
|---------|-----|
| Bot emulador | `http://10.0.2.2:8000` |
| Mac / host | `http://localhost:8000` |
| EC2 prod | `http://54.225.198.82:8000` |
