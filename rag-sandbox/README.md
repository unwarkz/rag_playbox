# RAG Sandbox — Self-Hosted RAG & Agent Memory Stack

Modular Docker Compose stack for deploying RAG tools, vector databases, agent memory systems, LLM inference, and supporting infrastructure on a single server.

**Key features:**

- **27+ services**, each in its own compose file — mix and match freely
- **Group compose files** for one-command deployment of curated profiles
- **Portainer-compatible** variants (no host-mount or Dockerfile build dependencies)
- **All configuration via `.env`** variables with sensible defaults
- **Two Docker networks**: `rag-internal` (all services) and `rag-frontend` (UI + proxy)
- **Only Nginx Proxy Manager** exposes external ports (80 / 443 / 8020)
- **March 2026 Docker images** — pinned where possible, `latest` where upstream doesn't tag

---

## Table of Contents

1. [Architecture](#architecture)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Directory Structure](#directory-structure)
5. [Deployment Profiles](#deployment-profiles)
6. [Resource Allocation](#resource-allocation)
7. [Network Architecture](#network-architecture)
8. [Service Details](#service-details)
9. [Configuration](#configuration)
10. [Portainer Deployment](#portainer-deployment)
11. [Accessing Services](#accessing-services)
12. [Useful Commands](#useful-commands)
13. [Troubleshooting](#troubleshooting)
14. [Security Notes](#security-notes)
15. [License](#license)

---

## Architecture

The stack is organized into five logical layers:

```
┌─────────────────────────────────────────────────────────────────┐
│                     INFRASTRUCTURE                              │
│  Nginx Proxy Manager · LiteLLM · Langfuse · DBHub              │
├─────────────────────────────────────────────────────────────────┤
│                  PLATFORMS & UIs                                 │
│  RAGFlow · Dify (API+Worker+Sandbox+Web) · Open WebUI           │
│  (+Pipelines) · AnythingLLM                                     │
├────────────────────────┬────────────────────────────────────────┤
│   RAG & MEMORY         │         CMS                            │
│  LightRAG · Mem0       │  NocoDB · Directus · Teable            │
│  Hindsight             │                                        │
├────────────────────────┴────────────────────────────────────────┤
│                      AI / ML LAYER                              │
│  Ollama (LLM) · Infinity (embed + rerank)                       │
│  Docling · Tika · Unstructured                                  │
├─────────────────────────────────────────────────────────────────┤
│                      DATA LAYER                                 │
│  PostgreSQL+pgvector · Redis/Valkey · Qdrant · Neo4j · MinIO    │
└─────────────────────────────────────────────────────────────────┘
```

| Layer | Services | Role |
|-------|----------|------|
| **Data** | PostgreSQL+pgvector, Redis/Valkey, Qdrant, Neo4j, MinIO | Relational, cache, vector, graph, and object storage |
| **AI/ML** | Ollama, Infinity (×2), Docling, Tika, Unstructured | LLM inference, embedding, reranking, document parsing |
| **RAG & Memory** | LightRAG, Mem0, Hindsight | Graph RAG, semantic memory, agent timeline |
| **Platforms** | RAGFlow, Dify, Open WebUI (+Pipelines), AnythingLLM | End-user RAG applications and chat interfaces |
| **CMS** | NocoDB, Directus, Teable | Airtable-like data management and headless CMS |
| **Infrastructure** | Nginx Proxy Manager, LiteLLM, Langfuse, DBHub | Reverse proxy, LLM gateway, observability, MCP server |

---

## Prerequisites

| Requirement | Minimum |
|-------------|---------|
| Docker Engine | 24+ with Compose V2 (`docker compose`) |
| RAM | 10 GB (for a subset; all services need more) |
| CPU cores | 8 |
| OS | Linux recommended |
| `vm.max_map_count` | ≥ 262144 (required by RAGFlow / Infinity) |
| Domain name | Optional — for HTTPS via Nginx Proxy Manager |

Set `vm.max_map_count` on the host:

```bash
# Temporary (until reboot)
sudo sysctl -w vm.max_map_count=262144

# Persistent
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

---

## Quick Start

```bash
# 1. Clone the repository
git clone <repo-url> && cd rag-sandbox

# 2. Create your .env from the essential template and fill in passwords
cp .env.essential .env
# Edit .env — replace every CHANGE_ME_* value with a real secret

# 3. (Optional) Copy the full .env for all tuning options
#    cp .env.full .env   # includes resource limits, image tags, model names, etc.

# 4. Choose a deployment profile and start
#    Bare-minimum (PostgreSQL + Redis + RAGFlow):
docker compose -f docker-compose-group-minimal.yml up -d

#    Standard dev stack (databases + embedding + Ollama + Open WebUI):
docker compose -f docker-compose-minimal.yml up -d

#    Everything:
docker compose -f docker-compose-full.yml up -d

# 5. Access services
#    Via NPM admin:  http://<server>:8020  (admin@example.com / changeme — change immediately)
#    Via SSH tunnel:  ssh -L 9380:localhost:9380 user@server  →  http://localhost:9380 (RAGFlow)
```

---

## Directory Structure

```
rag-sandbox/
├── .env                                 # Full configuration (all variables + defaults)
├── .env.essential                       # Minimal template — passwords only
│
├── docker-compose-common.yml            # Shared anchors, networks, volumes
│
│   ── Individual service files ──
├── docker-compose-postgres.yml          # PostgreSQL + pgvector (Dockerfile build)
├── docker-compose-redis.yml             # Redis / Valkey
├── docker-compose-qdrant.yml            # Qdrant vector DB
├── docker-compose-neo4j.yml             # Neo4j graph DB
├── docker-compose-minio.yml             # MinIO S3 storage
├── docker-compose-embedding.yml         # Infinity embedding server
├── docker-compose-reranker.yml          # Infinity reranker server
├── docker-compose-ollama.yml            # Ollama LLM inference
├── docker-compose-docling.yml           # Docling document parser
├── docker-compose-tika.yml              # Apache Tika extraction
├── docker-compose-unstructured.yml      # Unstructured.io processing
├── docker-compose-lightrag.yml          # LightRAG engine
├── docker-compose-mem0.yml              # Mem0 semantic memory
├── docker-compose-hindsight.yml         # Hindsight agent memory
├── docker-compose-ragflow.yml           # RAGFlow platform
├── docker-compose-dify.yml              # Dify (API + Worker + Sandbox + Web)
├── docker-compose-openwebui.yml         # Open WebUI
├── docker-compose-pipelines.yml         # Open WebUI Pipelines
├── docker-compose-anythingllm.yml       # AnythingLLM
├── docker-compose-nocodb.yml            # NocoDB
├── docker-compose-directus.yml          # Directus CMS
├── docker-compose-teable.yml            # Teable spreadsheet DB
├── docker-compose-npm.yml               # Nginx Proxy Manager + MariaDB
├── docker-compose-litellm.yml           # LiteLLM proxy
├── docker-compose-langfuse.yml          # Langfuse observability
├── docker-compose-dbhub.yml             # DBHub MCP server
│
│   ── Group / profile files ──
├── docker-compose-group-minimal.yml     # PG + Redis + RAGFlow
├── docker-compose-group-databases.yml   # PG + Redis + Qdrant + Neo4j + MinIO
├── docker-compose-group-ai.yml          # Embedding + Reranker + Ollama + Docling + Tika + Unstructured
├── docker-compose-group-rag.yml         # LightRAG + Mem0 + Hindsight
├── docker-compose-group-ui.yml          # RAGFlow + Dify + Open WebUI + Pipelines + AnythingLLM
├── docker-compose-group-cms.yml         # NocoDB + Directus + Teable
├── docker-compose-group-infra.yml       # NPM + LiteLLM + Langfuse + DBHub
├── docker-compose-minimal.yml           # PG + Redis + Qdrant + MinIO + Embedding + Ollama + Open WebUI
├── docker-compose-full.yml              # All services
│
│   ── Portainer-specific ──
├── Portainer/
│   ├── docker-compose-postgres.yml      # PG without Dockerfile build
│   ├── docker-compose-group-minimal.yml # Portainer-compatible minimal group
│   ├── docker-compose-group-databases.yml
│   └── docker-compose-full.yml          # Portainer-compatible full stack
│
│   ── Config files ──
├── configs/
│   ├── postgres/                        # PostgreSQL init scripts
│   ├── litellm/                         # LiteLLM config.yaml
│   └── lightrag/                        # LightRAG environment overrides
│
│   ── Build contexts ──
└── postgres/
    └── Dockerfile                       # Custom PG image (locale + extensions)
```

---

## Deployment Profiles

### Group Files

| File | Services | Use Case |
|------|----------|----------|
| `group-minimal` | PostgreSQL, Redis, RAGFlow | Bare minimum RAG platform |
| `group-databases` | PostgreSQL, Redis, Qdrant, Neo4j, MinIO | All storage backends |
| `group-ai` | Embedding, Reranker, Ollama, Docling, Tika, Unstructured | AI inference & document processing |
| `group-rag` | LightRAG, Mem0, Hindsight | RAG & agent memory engines |
| `group-ui` | RAGFlow, Dify, Open WebUI, Pipelines, AnythingLLM | User-facing platforms |
| `group-cms` | NocoDB, Directus, Teable | Data management & headless CMS |
| `group-infra` | NPM, LiteLLM, Langfuse, DBHub | Infrastructure & observability |
| `minimal` | PostgreSQL, Redis, Qdrant, MinIO, Embedding, Ollama, Open WebUI | Standard dev stack |
| `full` | **All 27+ services** | Complete platform |

### Custom Combinations

Cherry-pick individual compose files for exactly the services you need:

```bash
docker compose \
  -f docker-compose-common.yml \
  -f docker-compose-postgres.yml \
  -f docker-compose-redis.yml \
  -f docker-compose-qdrant.yml \
  -f docker-compose-embedding.yml \
  -f docker-compose-ollama.yml \
  -f docker-compose-ragflow.yml \
  -f docker-compose-npm.yml \
  up -d
```

> **Note:** Always include `docker-compose-common.yml` first — it defines shared networks, volumes, and YAML anchors used by all other files.

---

## Resource Allocation

All limits are configured via `.env` variables. Defaults are tuned for a **10 GB RAM / 8 CPU** server.

| Service | Container | CPU Limit | Memory Limit | Image |
|---------|-----------|-----------|--------------|-------|
| **PostgreSQL** | `rag-postgres` | 2.0 | 1536 MB | `pgvector/pgvector:pg17` |
| **Redis / Valkey** | `rag-redis` | 0.5 | 256 MB | `valkey/valkey:9.0.3-alpine` |
| **Qdrant** | `rag-qdrant` | 1.0 | 1024 MB | `qdrant/qdrant:v1.16.3` |
| **Neo4j** | `rag-neo4j` | 1.0 | 1024 MB | `neo4j:2026.02.3-community` |
| **MinIO** | `rag-minio` | 0.5 | 256 MB | `pgsty/minio:latest` |
| **Embedding** | `rag-embedding` | 2.0 | 1024 MB | `michaelf34/infinity:latest` |
| **Reranker** | `rag-reranker` | 1.0 | 768 MB | `michaelf34/infinity:latest` |
| **Ollama** | `rag-ollama` | 4.0 | 3072 MB | `ollama/ollama:latest` |
| **Docling** | `rag-docling` | 2.0 | 1024 MB | `quay.io/ds4sd/docling-serve:latest` |
| **Tika** | `rag-tika` | 1.0 | 512 MB | `apache/tika:latest-full` |
| **Unstructured** | `rag-unstructured` | 2.0 | 1024 MB | `downloads.unstructured.io/unstructured-io/unstructured:latest` |
| **LightRAG** | `rag-lightrag` | 1.0 | 512 MB | `ghcr.io/hkuds/lightrag:latest` |
| **Mem0** | `rag-mem0` | 1.0 | 512 MB | `mem0ai/mem0-server:latest` |
| **Hindsight** | `rag-hindsight` | 1.0 | 512 MB | `ghcr.io/vectorize-io/hindsight:latest` |
| **RAGFlow** | `rag-ragflow` | 2.0 | 1536 MB | `infiniflow/ragflow:v0.24.0` |
| **Dify API** | `rag-dify-api` | 1.5 | 768 MB | `langgenius/dify-api:1.13.2` |
| **Dify Worker** | `rag-dify-worker` | 1.0 | 512 MB | `langgenius/dify-api:1.13.2` |
| **Dify Sandbox** | `rag-dify-sandbox` | 0.5 | 256 MB | `langgenius/dify-sandbox:0.2.10` |
| **Dify Web** | `rag-dify-web` | 0.5 | 256 MB | `langgenius/dify-web:1.13.2` |
| **Open WebUI** | `rag-openwebui` | 1.0 | 512 MB | `ghcr.io/open-webui/open-webui:main` |
| **Pipelines** | `rag-pipelines` | 1.0 | 512 MB | `ghcr.io/open-webui/pipelines:main` |
| **AnythingLLM** | `rag-anythingllm` | 1.0 | 512 MB | `mintplexlabs/anythingllm:latest` |
| **NocoDB** | `rag-nocodb` | 0.5 | 256 MB | `nocodb/nocodb:latest` |
| **Directus** | `rag-directus` | 0.5 | 384 MB | `directus/directus:11.16` |
| **Teable** | `rag-teable` | 0.5 | 384 MB | `ghcr.io/teableio/teable:latest` |
| **NPM** | `rag-npm` | 0.5 | 256 MB | `jc21/nginx-proxy-manager:latest` |
| **NPM DB** | `rag-npm-db` | 0.5 | 256 MB | `jc21/mariadb-aria:latest` |
| **LiteLLM** | `rag-litellm` | 1.0 | 512 MB | `ghcr.io/berriai/litellm:main-v1.82.3-stable` |
| **Langfuse** | `rag-langfuse` | 1.0 | 512 MB | `langfuse/langfuse:3` |
| **DBHub** | `rag-dbhub` | 0.5 | 256 MB | `bytebase/dbhub:latest` |
| | | **Total** | **~31.5 CPU** | **~19.9 GB** | |

> ⚠ **Not all services can run simultaneously at full allocation.** The totals exceed a single 10 GB / 8 CPU server. Use [deployment profiles](#deployment-profiles) to select the services you need, or increase server resources for the full stack.

---

## Network Architecture

### Networks

| Network | Purpose | External Ports |
|---------|---------|----------------|
| `rag-internal` | Inter-service communication (APIs, databases) | None |
| `rag-frontend` | UI containers ↔ Nginx Proxy Manager | 80, 443, 8020 |

### Service-to-Network Mapping

| Network | Services |
|---------|----------|
| `rag-internal` only | postgres, redis, qdrant, neo4j, embedding, reranker, ollama, docling, tika, unstructured, dify-api, dify-worker, dify-sandbox, pipelines, mem0, litellm, dbhub |
| `rag-internal` + `rag-frontend` | minio, ragflow, dify-web, openwebui, anythingllm, lightrag, hindsight, nocodb, directus, teable, langfuse |
| `rag-frontend` only | nginx-proxy-manager, npm-db |

All inter-service traffic stays on `rag-internal`. Only Nginx Proxy Manager has host-bound ports.

---

## Service Details

### Data Layer

#### PostgreSQL + pgvector

- **Container:** `rag-postgres`
- **Internal endpoint:** `postgres:5432`
- **Image:** `pgvector/pgvector:pg17` (custom Dockerfile adds locale support)
- **Key variables:** `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- **Dependencies:** None
- **Notes:** Creates 11 databases at init (ragflow, dify, openwebui, lightrag, mem0, hindsight, directus, nocodb, teable, langfuse, litellm). Each database gets `vector`, `pg_trgm`, `unaccent`, and `uuid-ossp` extensions.

#### Redis / Valkey

- **Container:** `rag-redis`
- **Internal endpoint:** `redis:6379`
- **Image:** `valkey/valkey:9.0.3-alpine`
- **Key variables:** `REDIS_PASSWORD`, `REDIS_MAXMEMORY`
- **Dependencies:** None
- **Notes:** Redis databases are partitioned: db:0 (RAGFlow), db:1 (Dify cache), db:2 (Dify Celery), db:3 (LightRAG/Directus), db:6 (NocoDB), db:7 (Teable), db:8 (LiteLLM cache).

#### Qdrant

- **Container:** `rag-qdrant`
- **Internal endpoint:** `qdrant:6333` (REST), `qdrant:6334` (gRPC)
- **Image:** `qdrant/qdrant:v1.16.3`
- **Key variables:** `QDRANT_API_KEY`
- **Dependencies:** None

#### Neo4j

- **Container:** `rag-neo4j`
- **Internal endpoint:** `neo4j:7474` (HTTP), `neo4j:7687` (Bolt)
- **Image:** `neo4j:2026.02.3-community`
- **Key variables:** `NEO4J_AUTH`, `NEO4J_PLUGINS`
- **Dependencies:** None
- **Notes:** Plugins APOC and Graph Data Science are loaded at startup.

#### MinIO

- **Container:** `rag-minio`
- **Internal endpoint:** `minio:9000` (S3 API), `minio:9001` (Console)
- **Image:** `pgsty/minio:latest`
- **Key variables:** `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`
- **Dependencies:** None

### AI / ML Layer

#### Embedding Server (Infinity)

- **Container:** `rag-embedding`
- **Internal endpoint:** `embedding:7997`
- **Image:** `michaelf34/infinity:latest`
- **Model:** `Qwen/Qwen3-Embedding-0.6B`
- **Key variables:** `EMBED_MODEL`, `EMBED_PORT`, `EMBED_BATCH_SIZE`
- **Dependencies:** None
- **Notes:** OpenAI-compatible API at `/v1`. Shares `models-cache` volume with reranker.

#### Reranker Server (Infinity)

- **Container:** `rag-reranker`
- **Internal endpoint:** `reranker:7998`
- **Image:** `michaelf34/infinity:latest`
- **Model:** `BAAI/bge-reranker-v2-m3`
- **Key variables:** `RERANK_MODEL`, `RERANK_PORT`
- **Dependencies:** None

#### Ollama

- **Container:** `rag-ollama`
- **Internal endpoint:** `ollama:11434`
- **Image:** `ollama/ollama:latest`
- **Models:** `qwen3:14b`, `qwen3:1.7b` (pull after startup)
- **Key variables:** `OLLAMA_NUM_PARALLEL`, `OLLAMA_MAX_LOADED_MODELS`, `OLLAMA_KEEP_ALIVE`
- **Dependencies:** None

#### Docling

- **Container:** `rag-docling`
- **Internal endpoint:** `docling:5001`
- **Image:** `quay.io/ds4sd/docling-serve:latest`
- **Key variables:** `DOCLING_WORKERS`, `DOCLING_MAX_PAGES`
- **Dependencies:** None

#### Apache Tika

- **Container:** `rag-tika`
- **Internal endpoint:** `tika:9998`
- **Image:** `apache/tika:latest-full`
- **Key variables:** `TIKA_JAVA_OPTS`
- **Dependencies:** None

#### Unstructured

- **Container:** `rag-unstructured`
- **Internal endpoint:** `unstructured:8000`
- **Image:** `downloads.unstructured.io/unstructured-io/unstructured:latest`
- **Key variables:** `UNSTRUCTURED_API_KEY`
- **Dependencies:** None

### RAG & Memory

#### LightRAG

- **Container:** `rag-lightrag`
- **Internal endpoint:** `lightrag:9621`
- **Image:** `ghcr.io/hkuds/lightrag:latest`
- **Key variables:** `LIGHTRAG_LLM_MODEL`, `LIGHTRAG_EMBEDDING_MODEL`, `LIGHTRAG_CHUNK_SIZE`
- **Dependencies:** postgres, redis, qdrant, neo4j, embedding
- **Notes:** Graph-augmented RAG. Uses PostgreSQL for KV storage, Qdrant for vectors, Neo4j for the knowledge graph. LLM via Ollama, embedding via Infinity.

#### Mem0

- **Container:** `rag-mem0`
- **Internal endpoint:** `mem0:8888`
- **Image:** `mem0ai/mem0-server:latest`
- **Key variables:** `MEM0_API_KEY`, `MEM0_LLM_MODEL`, `MEM0_GRAPH_MEMORY_ENABLED`
- **Dependencies:** postgres, qdrant, neo4j, embedding
- **Notes:** Semantic memory layer with optional graph memory. API key protected.

#### Hindsight

- **Container:** `rag-hindsight`
- **Internal endpoints:** `hindsight:8889` (API), `hindsight:9999` (WebUI)
- **Image:** `ghcr.io/vectorize-io/hindsight:latest`
- **Key variables:** `HINDSIGHT_DB_URL`, `HINDSIGHT_QDRANT_URL`
- **Dependencies:** postgres, embedding

### Platforms & UIs

#### RAGFlow

- **Container:** `rag-ragflow`
- **Internal endpoint:** `ragflow:9380`
- **Image:** `infiniflow/ragflow:v0.24.0`
- **Dependencies:** postgres, redis, minio, embedding
- **Notes:** Document-centric RAG platform with built-in chunk management, embedding, and search.

#### Dify

Four containers from a single compose file:

| Container | Role | Internal Endpoint |
|-----------|------|-------------------|
| `rag-dify-api` | API server | `dify-api:5002` |
| `rag-dify-worker` | Celery worker | — (no HTTP) |
| `rag-dify-sandbox` | Code execution | `dify-sandbox:8194` |
| `rag-dify-web` | Next.js frontend | `dify-web:3000` |

- **Image:** `langgenius/dify-api:1.13.2` / `langgenius/dify-web:1.13.2` / `langgenius/dify-sandbox:0.2.10`
- **Dependencies:** postgres, redis, qdrant, minio

#### Open WebUI

- **Container:** `rag-openwebui`
- **Internal endpoint:** `openwebui:8080`
- **Image:** `ghcr.io/open-webui/open-webui:main`
- **Dependencies:** postgres, qdrant, ollama, embedding
- **Notes:** Chat interface with RAG support, pipelines integration.

#### Open WebUI Pipelines

- **Container:** `rag-pipelines`
- **Internal endpoint:** `pipelines:9099`
- **Image:** `ghcr.io/open-webui/pipelines:main`
- **Key variables:** `OPENWEBUI_PIPELINES_API_KEY`
- **Dependencies:** None

#### AnythingLLM

- **Container:** `rag-anythingllm`
- **Internal endpoint:** `anythingllm:3001`
- **Image:** `mintplexlabs/anythingllm:latest`
- **Dependencies:** qdrant, ollama, embedding

### CMS

#### NocoDB

- **Container:** `rag-nocodb`
- **Internal endpoint:** `nocodb:8080`
- **Image:** `nocodb/nocodb:latest`
- **Dependencies:** postgres, redis

#### Directus

- **Container:** `rag-directus`
- **Internal endpoint:** `directus:8055`
- **Image:** `directus/directus:11.16`
- **Dependencies:** postgres, redis, minio

#### Teable

- **Container:** `rag-teable`
- **Internal endpoint:** `teable:3000`
- **Image:** `ghcr.io/teableio/teable:latest`
- **Dependencies:** postgres, redis, minio

### Infrastructure

#### Nginx Proxy Manager

- **Container:** `rag-npm` (+ `rag-npm-db` MariaDB backend)
- **Internal endpoint:** `nginx-proxy-manager:81` (admin)
- **External ports:** `80` (HTTP), `443` (HTTPS), `8020` (Admin UI)
- **Image:** `jc21/nginx-proxy-manager:latest`
- **Default login:** `admin@example.com` / `changeme` — **change immediately**

#### LiteLLM

- **Container:** `rag-litellm`
- **Internal endpoint:** `litellm:4000`
- **Image:** `ghcr.io/berriai/litellm:main-v1.82.3-stable`
- **Key variables:** `LITELLM_MASTER_KEY`
- **Notes:** Unified LLM proxy supporting Ollama (local), OpenRouter, Qwen DashScope, Google Gemini, Moonshot Kimi. Langfuse integration for tracing.

#### Langfuse

- **Container:** `rag-langfuse`
- **Internal endpoint:** `langfuse:3000`
- **Image:** `langfuse/langfuse:3`
- **Dependencies:** postgres
- **Notes:** LLM observability and tracing. Bootstrap creates org "RAG Sandbox" and default project.

#### DBHub

- **Container:** `rag-dbhub`
- **Internal endpoint:** `dbhub:8033`
- **Image:** `bytebase/dbhub:latest`
- **Dependencies:** postgres
- **Notes:** Database MCP (Model Context Protocol) server — lets LLM agents query PostgreSQL.

---

## Configuration

### `.env.essential` vs `.env`

| File | Purpose | When to Use |
|------|---------|-------------|
| `.env.essential` | Only required secrets (passwords, API keys, JWT secrets) | Quick start — copy to `.env` and fill in values |
| `.env` | Complete configuration with all options and defaults | Full control over images, resource limits, model names, ports |

```bash
# Quick start
cp .env.essential .env
# Then edit .env and replace every CHANGE_ME_* value
```

### Shared Variables

These variables are used by multiple services:

| Variable | Used By | Description |
|----------|---------|-------------|
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_FROM` | Dify, Directus, Open WebUI, Teable | Email delivery settings |
| `LOG_LEVEL` | Multiple services | Global log level (`INFO` default) |
| `TZ` | All containers | Timezone (`UTC` default) |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | 11+ services | Shared PostgreSQL credentials |
| `REDIS_PASSWORD` | RAGFlow, Dify, LightRAG, Directus, NocoDB, Teable, LiteLLM | Shared Redis password |
| `QDRANT_API_KEY` | Dify, Open WebUI, AnythingLLM, LightRAG, Mem0, Hindsight | Qdrant authentication |

### Per-Service Overrides

Every `${VAR:-default}` in compose files can be overridden by setting the variable in `.env`. For example:

```bash
# Override Ollama CPU/memory limits
OLLAMA_CPU_LIMIT=6.0
OLLAMA_MEM_LIMIT=4096m

# Change embedding model
EMBED_MODEL=BAAI/bge-m3

# Use a different Redis image
REDIS_IMAGE=redis:7-alpine
```

---

## Portainer Deployment

Most compose files work directly in Portainer. The one exception is **PostgreSQL**, which uses a `Dockerfile` build in the standard version.

### Setup

1. In Portainer, create a new **Stack** from a Git repository or paste compose contents.
2. For stacks that include PostgreSQL, use the files from the `Portainer/` directory:

   | Standard File | Portainer File |
   |---------------|----------------|
   | `docker-compose-postgres.yml` | `Portainer/docker-compose-postgres.yml` |
   | `docker-compose-group-minimal.yml` | `Portainer/docker-compose-group-minimal.yml` |
   | `docker-compose-group-databases.yml` | `Portainer/docker-compose-group-databases.yml` |
   | `docker-compose-full.yml` | `Portainer/docker-compose-full.yml` |

3. The Portainer PostgreSQL variant uses an inline entrypoint to configure locale at runtime instead of a `Dockerfile RUN` command.
4. Group files in `Portainer/` reference parent compose files via `../` relative paths.
5. Add your `.env` variables in the Portainer Stack environment section.

---

## Accessing Services

### Via Nginx Proxy Manager (Production)

1. Open NPM admin at `http://<server>:8020`
2. Log in with `admin@example.com` / `changeme` and **change the password immediately**
3. Add **Proxy Hosts** for each UI service:

   | Domain | Forward Hostname | Forward Port |
   |--------|------------------|--------------|
   | `ragflow.example.com` | `ragflow` | `9380` |
   | `dify.example.com` | `dify-web` | `3000` |
   | `chat.example.com` | `openwebui` | `8080` |
   | `anythingllm.example.com` | `anythingllm` | `3001` |
   | `lightrag.example.com` | `lightrag` | `9621` |
   | `langfuse.example.com` | `langfuse` | `3000` |
   | `nocodb.example.com` | `nocodb` | `8080` |
   | `directus.example.com` | `directus` | `8055` |
   | `teable.example.com` | `teable` | `3000` |
   | `hindsight.example.com` | `hindsight` | `9999` |
   | `minio.example.com` | `minio` | `9001` |

4. Enable **SSL** via Let's Encrypt for each proxy host.

### Via SSH Tunnel (Development)

```bash
ssh -L 9380:localhost:9380 user@server   # RAGFlow
ssh -L 3000:localhost:3000 user@server   # Langfuse / Dify Web / Teable
ssh -L 8080:localhost:8080 user@server   # Open WebUI / NocoDB
ssh -L 8055:localhost:8055 user@server   # Directus
ssh -L 8020:localhost:8020 user@server   # NPM Admin
```

> **Note:** SSH tunnel requires the optional `*_HOST_PORT` variables to be set in `.env` for the services you want to tunnel.

### Internal Service Endpoints

For inter-service communication (e.g., configuring LLM endpoints in Dify):

| Service | Hostname:Port | Protocol |
|---------|---------------|----------|
| PostgreSQL | `postgres:5432` | PostgreSQL |
| Redis | `redis:6379` | Redis |
| Qdrant | `qdrant:6333` | HTTP REST |
| Qdrant gRPC | `qdrant:6334` | gRPC |
| Neo4j HTTP | `neo4j:7474` | HTTP |
| Neo4j Bolt | `neo4j:7687` | Bolt |
| MinIO S3 | `minio:9000` | S3 API |
| MinIO Console | `minio:9001` | HTTP |
| Embedding | `embedding:7997` | OpenAI-compatible |
| Reranker | `reranker:7998` | OpenAI-compatible |
| Ollama | `ollama:11434` | Ollama / OpenAI-compatible |
| Docling | `docling:5001` | HTTP REST |
| Tika | `tika:9998` | HTTP REST |
| Unstructured | `unstructured:8000` | HTTP REST |
| LightRAG | `lightrag:9621` | HTTP REST |
| Mem0 | `mem0:8888` | HTTP REST |
| Hindsight API | `hindsight:8889` | HTTP REST |
| Hindsight UI | `hindsight:9999` | HTTP |
| RAGFlow | `ragflow:9380` | HTTP |
| Dify API | `dify-api:5002` | HTTP REST |
| Dify Sandbox | `dify-sandbox:8194` | HTTP |
| Dify Web | `dify-web:3000` | HTTP |
| Open WebUI | `openwebui:8080` | HTTP |
| Pipelines | `pipelines:9099` | HTTP REST |
| AnythingLLM | `anythingllm:3001` | HTTP |
| NocoDB | `nocodb:8080` | HTTP |
| Directus | `directus:8055` | HTTP REST |
| Teable | `teable:3000` | HTTP |
| LiteLLM | `litellm:4000` | OpenAI-compatible |
| Langfuse | `langfuse:3000` | HTTP |
| DBHub | `dbhub:8033` | MCP / HTTP |
| NPM Admin | `nginx-proxy-manager:81` | HTTP |

---

## Useful Commands

```bash
# ── Lifecycle ──

# Start minimal profile
docker compose -f docker-compose-group-minimal.yml up -d

# Start standard dev stack
docker compose -f docker-compose-minimal.yml up -d

# Start everything
docker compose -f docker-compose-full.yml up -d

# Stop everything (preserves volumes)
docker compose -f docker-compose-full.yml down

# Stop and remove volumes (⚠ data loss)
docker compose -f docker-compose-full.yml down -v

# ── Updates ──

# Pull latest images
docker compose -f docker-compose-full.yml pull

# Recreate containers after pull
docker compose -f docker-compose-full.yml up -d --force-recreate

# ── Logs ──

# Follow logs for a specific service
docker compose -f docker-compose-full.yml logs -f ragflow

# Show last 100 lines
docker compose -f docker-compose-full.yml logs --tail 100 ollama

# ── Ollama Models ──

# Pull a model
docker exec rag-ollama ollama pull qwen3:14b

# List loaded models
docker exec rag-ollama ollama list

# ── Database ──

# Backup all PostgreSQL databases
docker exec rag-postgres pg_dumpall -U ragadmin > backup.sql

# Restore
cat backup.sql | docker exec -i rag-postgres psql -U ragadmin

# Connect to PostgreSQL
docker exec -it rag-postgres psql -U ragadmin -d ragdb

# ── Debugging ──

# Check resource usage
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Inspect a container's networks
docker inspect rag-ragflow --format '{{range .NetworkSettings.Networks}}{{.NetworkID}} {{end}}'

# Test internal connectivity
docker exec rag-ragflow curl -s http://embedding:7997/health
```

---

## Troubleshooting

### `vm.max_map_count` Too Low

**Symptoms:** RAGFlow or Infinity (embedding/reranker) fails to start with mmap errors.

```bash
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

### Out of Memory / OOM Kills

**Symptoms:** Containers restart unexpectedly; `docker inspect <container> | grep OOMKilled` shows `true`.

- Reduce the number of running services — use a smaller [deployment profile](#deployment-profiles)
- Lower memory limits for non-critical services in `.env`
- Ollama is the heaviest service (3 GB default) — reduce `OLLAMA_MEM_LIMIT` or use smaller models

### Service Dependency Startup Order

**Symptoms:** Services fail on first boot because databases aren't ready yet.

All services use `depends_on` with `condition: service_healthy`. On slow machines, increase Docker's default health check timeouts or simply run `docker compose up -d` again — healthy dependencies will resolve.

### Neo4j Plugin Loading Fails

**Symptoms:** Neo4j logs show plugin download errors.

- Ensure the container has internet access on first launch (plugins are downloaded from the Neo4j plugin repository)
- If behind a proxy, set `HTTP_PROXY`/`HTTPS_PROXY` in the Neo4j environment
- Plugins are cached in the `neo4j-plugins` volume after first successful download

### PostgreSQL Init Databases Missing

**Symptoms:** Services report "database does not exist".

The init script runs only on first launch (when `pg-data` volume is empty). If you changed database names after initial setup:

```bash
# Connect and create manually
docker exec -it rag-postgres psql -U ragadmin -c "CREATE DATABASE mydb;"
docker exec -it rag-postgres psql -U ragadmin -d mydb -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

### Embedding / Reranker Model Download Slow

**Symptoms:** Health checks time out during first startup while models download.

Models are downloaded to the shared `models-cache` volume on first launch. This can take several minutes depending on bandwidth. Check progress with:

```bash
docker logs -f rag-embedding
```

---

## Security Notes

> ⚠ **Change ALL default passwords before production use.** Every `Ch4ng3me_*` value in `.env` is a placeholder.

- **No external port exposure** — Only Nginx Proxy Manager binds to host ports (80, 443, 8020). All other services communicate exclusively over internal Docker networks.
- **HTTPS via NPM** — Configure Let's Encrypt SSL certificates in Nginx Proxy Manager for all external-facing services.
- **API key protection** — Qdrant, Unstructured, Mem0, LiteLLM, Pipelines, and Dify Sandbox all require API keys for access, even internally.
- **Database isolation** — Each service has its own PostgreSQL database with separate credentials.
- **Redis database partitioning** — Services use different Redis DB numbers to prevent key collisions.
- **NPM first-login** — The default NPM credentials (`admin@example.com` / `changeme`) must be changed on first login.
- **Secret rotation** — Langfuse, Directus, and Dify use cryptographic secrets (`NEXTAUTH_SECRET`, `DIRECTUS_SECRET`, `DIFY_SECRET_KEY`) that should be generated with `openssl rand -hex 32`.

---

## License

This repository contains Docker Compose orchestration files. Individual services are governed by their own licenses:

| Service | License |
|---------|---------|
| PostgreSQL / pgvector | PostgreSQL License |
| Valkey (Redis) | BSD-3-Clause |
| Qdrant | Apache 2.0 |
| Neo4j Community | GPL-3.0 |
| MinIO | AGPL-3.0 |
| Ollama | MIT |
| Infinity | MIT |
| Docling | MIT |
| Apache Tika | Apache 2.0 |
| Unstructured | Apache 2.0 |
| LightRAG | MIT |
| Mem0 | Apache 2.0 |
| RAGFlow | Apache 2.0 |
| Dify | Custom (Apache 2.0 base) |
| Open WebUI | MIT |
| AnythingLLM | MIT |
| NocoDB | AGPL-3.0 |
| Directus | BSL / GPL-3.0 |
| Teable | AGPL-3.0 |
| Nginx Proxy Manager | MIT |
| LiteLLM | MIT |
| Langfuse | MIT (with EE features) |
| DBHub | MIT |

See each project's repository for full license details.
