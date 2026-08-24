# MIDO FastAPI AI Service

FastAPI microservice for MIDO MVP-2 risk analysis and reviewer-facing LLM explanation.

## Responsibilities

- Dependency-aware vulnerability lookup via OSV (read-only evidence)
- Risk score / severity normalization for Spring Boot `AIClient`
- LLM-style explanation payload for reviewer workflow (rule-based fallback)

## Endpoints

| Method | Path | Description |
| --- | --- | --- |
| GET | `/health` | Service health check |
| POST | `/api/v1/risk/analyze` | Risk analysis for code + dependencies |
| POST | `/api/v1/risk/explain` | Reviewer explanation for detected risks |

## Local run

```bash
cd ai-service
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8090
```

## Environment

| Variable | Default | Description |
| --- | --- | --- |
| `MIDO_AI_MODEL_VERSION` | `mido-risk-v1` | Model version tag returned to Spring |
| `MIDO_AI_PROMPT_VERSION` | `explain-v1` | Prompt version tag returned to Spring |
| `MIDO_AI_OSV_API_BASE_URL` | `https://api.osv.dev/v1` | OSV API base URL |
| `MIDO_AI_REQUEST_TIMEOUT_SECONDS` | `10.0` | External API timeout |

## Tests

```bash
pytest
```

## Spring Boot integration

Spring Boot calls this service through `analysis.client.AiAnalysisClient`.
Configure `mido.ai.base-url` in `application.yml` (default: `http://localhost:8090`).
