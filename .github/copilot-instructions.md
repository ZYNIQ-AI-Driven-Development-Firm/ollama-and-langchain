# Copilot Instructions for ollama-and-langchain

## Project Overview
- **Backend**: FastAPI app in `api/app/` providing OpenAI-compatible API proxy to Ollama with API key auth, rate limiting, and usage tracking
- **Frontend**: Next.js app in `frontend/` (TypeScript, TailwindCSS) for web interface
- **Infrastructure**: Full Docker stack with Postgres, Redis, Prometheus/Grafana monitoring, and Caddy reverse proxy
- **Security**: API key-based auth with hashed keys, model access control, and rate limiting per key
- **Observability**: Complete metrics pipeline with Prometheus scraping and Grafana dashboards

## Architecture Patterns
- **OpenAI Compatibility**: `/v1/chat/completions` and `/v1/models` endpoints mirror OpenAI API
- **Multi-tenant**: API keys control model access via `allowed_models` field (comma-separated or `*`)
- **Usage Tracking**: All requests logged to `usage_events` table with tokens, latency, cost
- **Model Aliasing**: Frontend aliases (e.g., `gpt-4`) map to Ollama backend tags (e.g., `llama2:13b`)
- **Health Checks**: All services have proper health checks in docker-compose for reliability

## Key Workflows
- **Development**: Use `make dev` for hot-reload stack, individual services via docker-compose
- **Production**: Use `make up` for detached mode, `make migrate` for DB migrations  
- **API Key Management**: Create via `/admin/keys/` (returns plaintext key once), validate via Bearer auth
- **Model Bootstrap**: Ollama pulls models from `OLLAMA_MODELS` env var at startup via `ollama_bootstrap.sh`
- **Monitoring**: Grafana at localhost:3000 (admin/admin), Prometheus metrics auto-exposed

## Database Schema (SQLAlchemy)
- **Users**: Admin users with email/password auth (`role` field for RBAC)
- **APIKey**: Hashed keys with `owner_id`, `allowed_models`, `concurrency_limit`, `rate_limit_rpm`, `monthly_budget`
- **Model**: Alias mapping (`alias` -> `backend_tag`) with enabled/disabled flag
- **UsageEvent**: Request logging with token counts, latency, status, cost tracking
- **App**: Multi-tenancy support (placeholder for future app-scoped resources)

## Security & Production Patterns  
- **API Key Auth**: SHA-256 hashed keys, Bearer token validation in `security.py`
- **Rate Limiting**: Per-key RPM limits and concurrency controls (models define limits)
- **Environment Config**: All secrets via env vars (see `config.py` for required vars)
- **Health Checks**: Postgres, Redis, Ollama all have health checks for graceful startup
- **HTTPS Ready**: Caddy handles TLS termination with Let's Encrypt staging by default

## Critical Environment Variables
```bash
POSTGRES_DSN=postgresql+psycopg://app:pass@db:5432/llm
OLLAMA_BASE_URL=http://ollama:11434  
OLLAMA_MODELS=llama2,codellama  # Comma-separated, pulled at startup
ADMIN_EMAIL=admin@example.com   # Auto-created user with default password
JWT_SECRET=supersecret          # Change in production!
```

## Common Tasks
- **Add API Route**: Create router in `api/app/routers/`, include in `main.py`
- **Add Model**: Create in `models.py`, schema in `schemas.py`, CRUD operations in `crud.py`  
- **Database Migration**: `make migrate` runs `alembic upgrade head`
- **New API Key**: POST to `/admin/keys/` with `allowed_models`, `rate_limit_rpm`, etc.
- **Model Management**: Update `Model` table to map frontend aliases to Ollama backend tags

## Deployment & Cloud Ready
- **Docker**: Multi-stage builds for api/frontend, separate Ollama container with GPU support
- **GCP Cloud Build**: `cloudbuild.yaml` builds Ollama image to GCR
- **Monitoring Stack**: Prometheus + Grafana with persistent volumes
- **Proxy**: Caddy handles routing `/api/*` to backend, `/*` to frontend with auto-HTTPS

## Key Files for AI Context
- `api/app/main.py`: Startup logic, router registration, admin user creation
- `api/app/routers/openai.py`: OpenAI-compatible endpoints with auth and model access control
- `api/app/models.py`: Complete database schema with relationships
- `docker-compose.yml`: Full production stack with health checks and volumes
- `Makefile`: Essential commands for development and deployment workflows
