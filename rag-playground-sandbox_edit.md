# RAG Playground Sandbox

## Docker Compose Гайд · Март 2026 · CPU-only

> **Принцип документа:** каждый сервис — отдельный именованный блок. Собирай свой `docker-compose.yml` копируя нужные блоки. Общая часть (сети, тома, якоря) идёт первой и обязательна.


---


---

# Требуются изменения

во внешнюю сеть необходимо открыть  ТОЛЬКО порты веб-интерфейсов. ВСЕ ОСТАЛЬНЫЕ ПОРТЫ НЕ ДОЛЖНЫ БЫТЬ ПРОПИСАНЫ В СЕРВИСАХ, они будут доступны внутри докер-сети, этого достаточно.
Точечные изменения инструкций, которые надо исправить перед внедрением отмечаны разделами предупреждение. Пример (подлежит исполнению):


:::warning
во внешнюю сеть необходимо открыть  ТОЛЬКО порты веб-интерфейсов. ВСЕ ОСТАЛЬНЫЕ ПОРТЫ НЕ ДОЛЖНЫ БЫТЬ ПРОПИСАНЫ В СЕРВИСАХ, они будут доступны внутри докер-сети, этого достаточно. 
Сеть rag-internal - для внутреннего доступа, в ней должны быть все контейнеры.
Сеть rag-frontend - для доступа к webui контейнеров, там есть только контейнеры с интерфейсами. апи - это не интерфейс. к ней же будет подключен проксименеджер, который будет пробрасывать порты через внутренние имена контейнеров, поэтому порты публиковать не нужно.
Прописать в компоуз ВСЕ указанные environment ключи в виде переменных со значениями по умолчанию, чтобы их можно было легко переопределить через .env


:::

все такие разделы в документе требуют внесения описанных в них изменений.
зачеркнутый текст в документе не соответствует задачам либо действительности
~~зачеркнутый текст~~

После проведения изменений, предупреждения и зачеркнутые блоки удалить.

Учитывать, что запуск будет производиться из portainer в режиме repository, значит никаких файлов мы добавить в образы или контейнеры не можем, только текст в докерфайлах и компоуз файлах.


:::warning
Добавить Apache Tika, unstructured-io, DBHub, open-webui/pipelines, langfuse/langfuse

:::


## 1. Структура файлов


:::warning
поправить в соответствии со всеми изменениями в документе после их внесения

:::

```
rag-sandbox/
├── docker-compose.yml        ← собираешь сам из блоков ниже
├── .env                      ← полный файл из раздела 3
├── configs/
│   ├── postgres/
│   │   └── init.sql          ← раздел 25
│   ├── ragflow/
│   │   └── service_conf.yaml ← копируется из RAGFlow repo
│   ├── lightrag/
│   │   └── .env.lightrag     ← env-файл для LightRAG сервиса
│   └── nginx-proxy-manager/
│       └── (данные пишутся в тома автоматически)
├── models/                   ← кеш HuggingFace моделей (Infinity)
├── data/
│   ├── postgres/
│   ├── redis/
│   ├── qdrant/
│   ├── neo4j/
│   ├── minio/
│   ├── ragflow/
│   ├── dify/
│   ├── openwebui/
│   ├── anythingllm/
│   ├── lightrag/
│   ├── hindsight/
│   ├── mem0/
│   ├── nocodb/
│   ├── directus/
│   ├── teable/
│   └── npm/                  ← Nginx Proxy Manager data
└── secrets/                  ← опционально для Docker secrets
```


---

## 2. Заметки перед стартом

### pgsty/minio — почему не minio/minio

В октябре 2025 MinIO прекратил публикацию бинарей и Docker-образов; в феврале 2026 репозиторий официально переведён в архив. `pgsty/minio` — community fork от команды Pigsty, drop-in замена: те же порты (9000 API, 9001 console), те же env-переменные, исправленные CVE, восстановленный admin console UI. Просто замени `minio/minio` на `pgsty/minio`.

### Ollama и «облачные» модели

Для реализации авторизации при проксировании облачных моделей в Ollama необходимо разделить процесс на две части: внутреннюю авторизацию (между вашим сервером и облаком Ollama) и внешнюю (между клиентами и вашим сервером).


1. Авторизация вашего сервера в облаке Ollama Чтобы ваш экземпляр Ollama мог обращаться к облачным моделям (например, с тегом :cloud), сервер должен быть авторизован под вашей учетной записью. Ollama Ollama Командная строка: Выполните команду ollama signin на сервере. Это создаст необходимые ключи для автоматической подписи запросов к [ollama.com](http://ollama.com).
2. API Ключ: Для программного доступа можно создать API ключ в настройках профиля на сайте и установить переменную окружения OLLAMA_API_KEY.

   ```bash
   export OLLAMA_API_KEY="ваш_ключ" Используйте код с осторожностью.
   
   ```


### RAGFlow и PostgreSQL

RAGFlow v0.24.0+ поддерживает PostgreSQL вместо MySQL. Для поиска документов используется либо Elasticsearch, либо **Infinity** (встроенный движок InfiniFlow). В этом гайде — Infinity (легче, нет Java-overhead). При этом RAGFlow создаёт собственную БД в PostgreSQL и управляет ей сам.

### pgvectorscale и pg_bm25

`~~pgvectorscale~~` ~~и~~ `~~pg_bm25~~` ~~(ParadeDB) требуют специального образа. Используем~~ `~~paradedb/paradedb:latest~~` ~~— он включает PostgreSQL + pgvector + pgvectorscale + pg_bm25 + полнотекстовые возможности. Это расширяет возможности стандартного~~ `~~pgvector/pgvector:pg17~~`~~.
~~


:::warning
для сборки надо сделать докерфайл и собрать локаль из .env пременной POSTGRES_LOCALE (добавить ее), и прописать ее в POSTGRES_INITDB_ARGS, установить pgvector + pgvectorscale + pg_bm25.
написать текст в этом параграфе.

:::

### Без GPU — настройки Infinity

Все Infinity-сервисы запускаются с флагом `--device cpu`. На CPU модель `Qwen3-Embedding-0.6B` (\~300MB) инферится быстрее `BGE-M3` (\~1.3GB). Для реранкера берём `bge-reranker-v2-m3` — он меньше, чем `bge-reranker-v2-gemma`.

### vm.max_map_count (обязательно для RAGFlow)


:::warning
написать объяснение в этом параграфе

:::

```bash
sudo sysctl -w vm.max_map_count=262144
# Постоянно:
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```


---

## 3. `.env` — полный файл


:::warning
добавить недостающие переменные, убрать лишние (порты, которые не должны смотреть во внешнюю сеть)
добавить лимиты по cpu и оперативной памяти - индивидуальный для каждого сервиса и стандартный, который применяется если не определен индивидуальный. выставить значения по умолчанию, подходящие для сервера на 10ГБ и 8 cpu. прописать в компоузах.

:::

```dotenv
# ================================================================
# RAG SANDBOX — Полный .env
# Март 2026
# ================================================================

# ----------------------------------------------------------------
# ОБЩИЕ
# ----------------------------------------------------------------
TZ=Asia/Almaty
COMPOSE_PROJECT_NAME=rag-sandbox

# ----------------------------------------------------------------
# POSTGRESQL
# ----------------------------------------------------------------
POSTGRES_IMAGE=paradedb/paradedb:latest
# Основной суперпользователь
POSTGRES_USER=ragadmin
POSTGRES_PASSWORD=Ch4ng3me_P0stgres!
POSTGRES_DB=ragdb
POSTGRES_PORT=5432
# Локаль для ru_RU поддержки
POSTGRES_INITDB_ARGS=--locale=ru_RU.UTF-8 --encoding=UTF8
# Отдельные базы для сервисов (создаются в init.sql)
# ragflow, dify, directus, nocodb, teable, lightrag, mem0, hindsight

# ----------------------------------------------------------------
# REDIS / VALKEY
# ----------------------------------------------------------------
REDIS_IMAGE=valkey/valkey:8-alpine
REDIS_PORT=6379
REDIS_PASSWORD=Ch4ng3me_R3dis!
# db-индексы по сервисам:
# 0: ragflow  1: dify  2: openwebui  3: lightrag
# 4: mem0     5: hindsight  6: session-cache  7: общий

# ----------------------------------------------------------------
# QDRANT
# ----------------------------------------------------------------
QDRANT_IMAGE=qdrant/qdrant:v1.13.0
QDRANT_PORT=6333
QDRANT_GRPC_PORT=6334
QDRANT_API_KEY=Ch4ng3me_Qdr4nt!
# Коллекции по сервисам создаются автоматически через API

# ----------------------------------------------------------------
# NEO4J
# ----------------------------------------------------------------
NEO4J_IMAGE=neo4j:5.26-community
NEO4J_HTTP_PORT=7474
NEO4J_BOLT_PORT=7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=Ch4ng3me_Neo4j!
NEO4J_PLUGINS=["apoc","graph-data-science"]
NEO4J_HEAP_INITIAL=512m
NEO4J_HEAP_MAX=2G
NEO4J_PAGECACHE=1G

# ----------------------------------------------------------------
# MINIO (pgsty fork — drop-in замена minio/minio)
# ----------------------------------------------------------------
MINIO_IMAGE=pgsty/minio:latest
MINIO_API_PORT=9000
MINIO_CONSOLE_PORT=9001
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=Ch4ng3me_Min10!
# Бакеты создаются сервисами автоматически при первом запуске

# ----------------------------------------------------------------
# INFINITY (Embedding + Reranker — CPU режим)
# ----------------------------------------------------------------
INFINITY_IMAGE=michaelf34/infinity:latest
# Embedding модель (Qwen3 лучше на CPU чем BGE-M3 за счёт меньшего размера)
EMBED_MODEL=Qwen/Qwen3-Embedding-0.6B
EMBED_PORT=7997
EMBED_SERVED_NAME=Qwen3-Embedding-0.6B
# Reranker модель
RERANK_MODEL=BAAI/bge-reranker-v2-m3
RERANK_PORT=7998
RERANK_SERVED_NAME=bge-reranker-v2-m3
# HuggingFace зеркало (если нужно)
HF_ENDPOINT=https://huggingface.co
# HF_ENDPOINT=https://hf-mirror.com  # Раскомментируй для зеркала

# ----------------------------------------------------------------
# OLLAMA (локальные модели + точка доступа для остальных)
# ----------------------------------------------------------------
OLLAMA_IMAGE=ollama/ollama:latest
OLLAMA_PORT=11434
# Bearer token для доступа к Ollama из других контейнеров
OLLAMA_API_TOKEN=Ch4ng3me_0ll4ma!
# Модели загружаются отдельно: docker exec rag-ollama ollama pull <model>
# Локальные embed: docker exec rag-ollama ollama pull qwen3:0.6b
# Для облачных моделей — смотри раздел 27 (LiteLLM)

# ----------------------------------------------------------------
# DOCLING
# ----------------------------------------------------------------
DOCLING_IMAGE=quay.io/ds4sd/docling-serve:latest
DOCLING_PORT=5001

# ----------------------------------------------------------------
# LIGHTRAG
# ----------------------------------------------------------------
LIGHTRAG_IMAGE=ghcr.io/hkuds/lightrag:latest
LIGHTRAG_PORT=9621
# LightRAG использует общие PG + Qdrant + Neo4j + Redis
LIGHTRAG_WORKSPACE=lightrag
# LLM для LightRAG (через Ollama или внешний провайдер)
LIGHTRAG_LLM_BINDING=openai
LIGHTRAG_LLM_BINDING_HOST=http://ollama:11434/v1
LIGHTRAG_LLM_MODEL=qwen3:14b
LIGHTRAG_LLM_API_KEY=ollama
LIGHTRAG_EMBEDDING_BINDING=openai
LIGHTRAG_EMBEDDING_BINDING_HOST=http://embedding:7997/v1
LIGHTRAG_EMBEDDING_MODEL=Qwen3-Embedding-0.6B
LIGHTRAG_EMBEDDING_DIM=1024

# ----------------------------------------------------------------
# MEM0
# ----------------------------------------------------------------
MEM0_IMAGE=mem0ai/mem0-server:latest
MEM0_PORT=8888
# Mem0 LLM provider (Ollama-compatible)
MEM0_LLM_PROVIDER=openai
MEM0_LLM_BASE_URL=http://ollama:11434/v1
MEM0_LLM_API_KEY=ollama
MEM0_LLM_MODEL=qwen3:14b
MEM0_EMBEDDER_PROVIDER=openai
MEM0_EMBEDDER_BASE_URL=http://embedding:7997/v1
MEM0_EMBEDDER_API_KEY=infinity
MEM0_EMBEDDER_MODEL=Qwen3-Embedding-0.6B

# ----------------------------------------------------------------
# HINDSIGHT
# ----------------------------------------------------------------
HINDSIGHT_IMAGE=ghcr.io/vectorize-io/hindsight:latest
HINDSIGHT_API_PORT=8889
HINDSIGHT_UI_PORT=9999
# LLM для Hindsight (fact extraction, entity resolution)
HINDSIGHT_API_LLM_PROVIDER=openai
HINDSIGHT_API_LLM_BASE_URL=http://ollama:11434/v1
HINDSIGHT_API_LLM_API_KEY=ollama
HINDSIGHT_API_LLM_MODEL=qwen3:14b
# Embedding (внешний Infinity)
HINDSIGHT_API_EMBEDDING_PROVIDER=openai
HINDSIGHT_API_EMBEDDING_BASE_URL=http://embedding:7997/v1
HINDSIGHT_API_EMBEDDING_API_KEY=infinity
HINDSIGHT_API_EMBEDDING_MODEL=Qwen3-Embedding-0.6B
# Reranker
HINDSIGHT_API_RERANKER_BASE_URL=http://reranker:7998/v1
HINDSIGHT_API_RERANKER_MODEL=bge-reranker-v2-m3

# ----------------------------------------------------------------
# RAGFLOW
# ----------------------------------------------------------------
RAGFLOW_IMAGE=infiniflow/ragflow:v0.26.0
RAGFLOW_PORT=8021
RAGFLOW_API_PORT=8022
# RAGFlow использует Infinity как document engine (легче чем ES)
DOC_ENGINE=infinity
# SVR_HTTP_PORT внутри контейнера
RAGFLOW_SVR_PORT=9380
RAGFLOW_TIMEZONE=Asia/Almaty
# Модели (настраиваются в UI после запуска)
# Embedding и chat модели указываются в UI → Model Providers

# ----------------------------------------------------------------
# DIFY
# ----------------------------------------------------------------
DIFY_IMAGE=langgenius/dify-api:1.4.0
DIFY_WEB_IMAGE=langgenius/dify-web:1.4.0
DIFY_SANDBOX_IMAGE=langgenius/dify-sandbox:0.2.10
DIFY_PORT=8023
DIFY_SECRET_KEY=Ch4ng3me_D1fy_Secret_32chars_min!
# SMTP (опционально, для инвайтов и сбросов пароля)
DIFY_MAIL_TYPE=smtp
DIFY_MAIL_DEFAULT_SEND_FROM=dify@example.com
DIFY_SMTP_SERVER=smtp.example.com
DIFY_SMTP_PORT=587
DIFY_SMTP_USERNAME=dify@example.com
DIFY_SMTP_PASSWORD=your_smtp_password
DIFY_SMTP_USE_TLS=true
# Начальный аккаунт
DIFY_INIT_EMAIL=admin@example.com
DIFY_INIT_PASSWORD=Ch4ng3me_D1fy!

# ----------------------------------------------------------------
# OPEN WEBUI
# ----------------------------------------------------------------
OPENWEBUI_IMAGE=ghcr.io/open-webui/open-webui:main
OPENWEBUI_PORT=8024
OPENWEBUI_SECRET_KEY=Ch4ng3me_0penWebUI_Secret!
# RAG backend (qdrant)
OPENWEBUI_VECTOR_DB=qdrant
# SMTP
OPENWEBUI_SMTP_SERVER=smtp.example.com
OPENWEBUI_SMTP_PORT=587
OPENWEBUI_SMTP_USERNAME=webui@example.com
OPENWEBUI_SMTP_PASSWORD=your_smtp_password
OPENWEBUI_SMTP_FROM=webui@example.com

# ----------------------------------------------------------------
# ANYTHINGLLM
# ----------------------------------------------------------------
ANYTHINGLLM_IMAGE=mintplexlabs/anythingllm:latest
ANYTHINGLLM_PORT=8025
ANYTHINGLLM_JWT_SECRET=Ch4ng3me_ALLM_JWT_Secret_32ch!
# Storage key для шифрования
ANYTHINGLLM_STORAGE_DIR=/app/server/storage

# ----------------------------------------------------------------
# NOCODB
# ----------------------------------------------------------------
NOCODB_IMAGE=nocodb/nocodb:latest
NOCODB_PORT=8026
NOCODB_SECRET=Ch4ng3me_NoCoDB_Secret!
NOCODB_DB=nocodb

# ----------------------------------------------------------------
# DIRECTUS
# ----------------------------------------------------------------
DIRECTUS_IMAGE=directus/directus:11
DIRECTUS_PORT=8027
DIRECTUS_SECRET=Ch4ng3me_D1rectus_Secret_32ch!
DIRECTUS_DB=directus
DIRECTUS_ADMIN_EMAIL=admin@example.com
DIRECTUS_ADMIN_PASSWORD=Ch4ng3me_D1rectus!
# SMTP
DIRECTUS_EMAIL_FROM=directus@example.com
DIRECTUS_EMAIL_SMTP_HOST=smtp.example.com
DIRECTUS_EMAIL_SMTP_PORT=587
DIRECTUS_EMAIL_SMTP_USER=directus@example.com
DIRECTUS_EMAIL_SMTP_PASSWORD=your_smtp_password
DIRECTUS_EMAIL_SMTP_SECURE=false

# ----------------------------------------------------------------
# TEABLE
# ----------------------------------------------------------------
TEABLE_IMAGE=ghcr.io/teableio/teable:latest
TEABLE_PORT=8028
TEABLE_SECRET=Ch4ng3me_T3able_Secret_32char!
TEABLE_DB=teable
TEABLE_PUBLIC_ORIGIN=http://localhost:8028
# SMTP
TEABLE_MAIL_HOST=smtp.example.com
TEABLE_MAIL_PORT=587
TEABLE_MAIL_USER=teable@example.com
TEABLE_MAIL_PASS=your_smtp_password
TEABLE_MAIL_FROM=teable@example.com

# ----------------------------------------------------------------
# NGINX PROXY MANAGER
# ----------------------------------------------------------------
NPM_IMAGE=jc21/nginx-proxy-manager:latest
NPM_HTTP_PORT=80
NPM_HTTPS_PORT=443
NPM_ADMIN_PORT=8020
NPM_DB_MYSQL_IMAGE=jc21/mariadb-aria:latest
NPM_MYSQL_DATABASE=npm
NPM_MYSQL_USER=npm
NPM_MYSQL_PASSWORD=Ch4ng3me_NPM_Mysql!
NPM_MYSQL_ROOT_PASSWORD=Ch4ng3me_NPM_Root!

# ----------------------------------------------------------------
# ВНЕШНИЕ ПРОВАЙДЕРЫ МОДЕЛЕЙ
# (используются в настройках каждой платформы)
# ----------------------------------------------------------------
# OpenRouter
OPENROUTER_API_KEY=sk-or-v1-your_key_here
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1

# Google Gemini
GEMINI_API_KEY=your_gemini_key_here

# Qwen (Alibaba Cloud)
QWEN_API_KEY=your_qwen_key_here
QWEN_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1

# HuggingFace
HF_TOKEN=hf_your_token_here

# Kimi (Moonshot AI)
KIMI_API_KEY=your_kimi_key_here
KIMI_BASE_URL=https://api.moonshot.cn/v1

# MiniMax
MINIMAX_API_KEY=your_minimax_key_here
MINIMAX_BASE_URL=https://api.minimax.chat/v1

# ----------------------------------------------------------------
# ЛОГИРОВАНИЕ
# ----------------------------------------------------------------
LOG_DRIVER=json-file
LOG_MAX_SIZE=50m
LOG_MAX_FILE=3
```


---

## 4. ОБЩАЯ ЧАСТЬ compose

> **Копируй этот блок первым — обязателен для всех конфигураций.**
>
> 
:::warning
> добавить лимиты из прошлого блока
>
> :::

```yaml
# ================================================================
# RAG SANDBOX — docker-compose.yml
# Март 2026 | CPU-only | Self-hosted
# ================================================================
# Собери свой файл: скопируй раздел 4, затем нужные сервисы (5–23)
# ================================================================

name: rag-sandbox

# ----------------------------------------------------------------
# ЯКОРЯ (YAML anchors) — переиспользуются в сервисах
# ----------------------------------------------------------------
x-restart: &restart
  restart: unless-stopped

x-logging: &logging
  logging:
    driver: "${LOG_DRIVER:-json-file}"
    options:
      max-size: "${LOG_MAX_SIZE:-50m}"
      max-file: "${LOG_MAX_FILE:-3}"

x-depends-db: &depends-db
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy

x-depends-full: &depends-full
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy
    qdrant:
      condition: service_healthy
    minio:
      condition: service_healthy

# ----------------------------------------------------------------
# СЕТИ
# ----------------------------------------------------------------
networks:
  rag-internal:
    name: rag-internal
    driver: bridge
    # Внутренняя сеть: БД, сервисы памяти, эмбеддеры, недоступна из интернета
  rag-frontend:
    name: rag-frontend
    driver: bridge
    # Фронтенд-сеть: UI-сервисы + NPM, доступна из интернета

# ----------------------------------------------------------------
# ТОМА
# ----------------------------------------------------------------
volumes:
  # БД
  pg-data:
  redis-data:
  qdrant-data:
  neo4j-data:
  neo4j-logs:
  neo4j-import:
  neo4j-plugins:
  minio-data:
  # Модели
  models-cache:       # HuggingFace cache для Infinity
  ollama-data:        # Ollama модели
  # RAG сервисы
  lightrag-data:
  mem0-data:
  hindsight-data:
  docling-cache:
  # UI
  ragflow-data:
  dify-storage:
  openwebui-data:
  anythingllm-data:
  # CMS
  nocodb-data:
  directus-uploads:
  teable-data:
  # NPM
  npm-data:
  npm-letsencrypt:
  npm-mysql:
```


---

## 5. БД — PostgreSQL + pgvector

> **~~Образ: ~~**`~~paradedb/paradedb:latest~~` ~~— включает pgvector + pgvectorscale + pg_bm25 + полнотекстовый поиск. Поддерживает~~ `~~ru_RU.UTF-8~~` ~~через~~ `~~POSTGRES_INITDB_ARGS~~`~~.~~
>
> 
:::warning
> не используем paradedb - лицензия AGPL.
> переписать на самосборный образ со сгенерированной локалью и добавленными расширениями, расписать докерфайл.
>
> :::

```yaml
  # ──────────────────────────────────────────────────────────────
  # POSTGRESQL (ParadeDB: pgvector + pgvectorscale + pg_bm25)
  # Порт: 5432 (внутренний + проброшен для dev-доступа)
  # ──────────────────────────────────────────────────────────────
  postgres:
    <<: *restart
    <<: *logging
    image: ${POSTGRES_IMAGE:-paradedb/paradedb:latest}
    container_name: rag-postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB:-ragdb}
      POSTGRES_INITDB_ARGS: ${POSTGRES_INITDB_ARGS:---locale=ru_RU.UTF-8 --encoding=UTF8}
      TZ: ${TZ:-Asia/Almaty}
      PGTZ: ${TZ:-Asia/Almaty}
    volumes:
      - pg-data:/var/lib/postgresql/data
      - ./configs/postgres/init.sql:/docker-entrypoint-initdb.d/00-init.sql:ro
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    networks:
      - rag-internal
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB:-ragdb}"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s
    shm_size: 256mb
```


---

## 6. БД — Redis / Valkey

> **Образ:** `valkey/valkey:8-alpine` — MIT-лицензия, drop-in замена Redis 7.2. Пароль через `--requirepass`.

```yaml
  # ──────────────────────────────────────────────────────────────
  # REDIS / VALKEY (MIT-лицензия)
  # Порт: 6379 (внутренний)
  # db-индексы: 0=ragflow 1=dify 2=openwebui 3=lightrag
  #             4=mem0 5=hindsight 6=session 7=общий
  # ──────────────────────────────────────────────────────────────
  redis:
    <<: *restart
    <<: *logging
    image: ${REDIS_IMAGE:-valkey/valkey:8-alpine}
    container_name: rag-redis
    command: >
      valkey-server
      --requirepass ${REDIS_PASSWORD}
      --save 60 1
      --save 300 10
      --maxmemory 2gb
      --maxmemory-policy allkeys-lru
      --loglevel notice
    volumes:
      - redis-data:/data
    ports:
      - "${REDIS_PORT:-6379}:6379"
    networks:
      - rag-internal
    healthcheck:
      test: ["CMD", "valkey-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
```


---

## 7. БД — Qdrant

> **Образ:** `qdrant/qdrant:v1.13.0` — Apache 2.0. Sparse + dense vectors, богатая фильтрация. Порты: 6333 (REST), 6334 (gRPC).

```yaml
  # ──────────────────────────────────────────────────────────────
  # QDRANT — векторная БД (Apache 2.0)
  # REST: 6333 | gRPC: 6334
  # Коллекции создаются автоматически через API каждым сервисом
  # ──────────────────────────────────────────────────────────────
  qdrant:
    <<: *restart
    <<: *logging
    image: ${QDRANT_IMAGE:-qdrant/qdrant:v1.13.0}
    container_name: rag-qdrant
    environment:
      QDRANT__SERVICE__API_KEY: ${QDRANT_API_KEY}
      QDRANT__SERVICE__ENABLE_STATIC_CONTENT: "false"
      QDRANT__LOG_LEVEL: INFO
    volumes:
      - qdrant-data:/qdrant/storage
    ports:
      - "${QDRANT_PORT:-6333}:6333"
      - "${QDRANT_GRPC_PORT:-6334}:6334"
    networks:
      - rag-internal
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:6333/healthz || exit 1"]
      interval: 15s
      timeout: 5s
      retries: 5
```


---

## 8. БД — Neo4j

> **Образ:** `neo4j:5.26-community` — GPL-3.0 Community. Включает APOC и Graph Data Science плагины. Используется LightRAG (GraphRAG), Mem0 (graph memory), Hindsight (entity graph).
>
> **Важно:** Плагины APOC и GDS скачиваются автоматически при первом старте через `NEO4J_PLUGINS`. Требует интернет при первом запуске.

```yaml
  # ──────────────────────────────────────────────────────────────
  # NEO4J — графовая БД (GPL-3.0 Community)
  # HTTP: 7474 | Bolt: 7687
  # Плагины: APOC + Graph Data Science (авто-загрузка)
  # ──────────────────────────────────────────────────────────────
  neo4j:
    <<: *restart
    <<: *logging
    image: ${NEO4J_IMAGE:-neo4j:5.26-community}
    container_name: rag-neo4j
    environment:
      NEO4J_AUTH: "${NEO4J_USER:-neo4j}/${NEO4J_PASSWORD}"
      NEO4J_PLUGINS: '${NEO4J_PLUGINS:-["apoc","graph-data-science"]}'
      NEO4J_dbms_security_procedures_unrestricted: "apoc.*,gds.*"
      NEO4J_dbms_security_procedures_allowlist: "apoc.*,gds.*"
      NEO4J_server_memory_heap_initial__size: ${NEO4J_HEAP_INITIAL:-512m}
      NEO4J_server_memory_heap_max__size: ${NEO4J_HEAP_MAX:-2G}
      NEO4J_server_memory_pagecache_size: ${NEO4J_PAGECACHE:-1G}
      NEO4J_server_bolt_advertised__address: neo4j:7687
      NEO4J_server_default__listen__address: 0.0.0.0
      TZ: ${TZ:-Asia/Almaty}
    volumes:
      - neo4j-data:/data
      - neo4j-logs:/logs
      - neo4j-import:/var/lib/neo4j/import
      - neo4j-plugins:/var/lib/neo4j/plugins
    ports:
      - "${NEO4J_HTTP_PORT:-7474}:7474"
      - "${NEO4J_BOLT_PORT:-7687}:7687"
    networks:
      - rag-internal
    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider http://localhost:7474 || exit 1"]
      interval: 20s
      timeout: 10s
      retries: 10
      start_period: 60s
```


---

## 9. БД — MinIO (pgsty fork)

> **Образ:** `pgsty/minio:latest` — community fork MinIO (оригинал архивирован февраль 2026). Drop-in совместимость. API: 9000, Web console: 9001.

```yaml
  # ──────────────────────────────────────────────────────────────
  # MINIO — S3-совместимое хранилище (pgsty fork, AGPL-3.0)
  # S3 API: 9000 | Web Console: 9001
  # Бакеты создаются сервисами автоматически
  # ──────────────────────────────────────────────────────────────
  minio:
    <<: *restart
    <<: *logging
    image: ${MINIO_IMAGE:-pgsty/minio:latest}
    container_name: rag-minio
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}
      MINIO_BROWSER_REDIRECT_URL: ""
      TZ: ${TZ:-Asia/Almaty}
    volumes:
      - minio-data:/data
    ports:
      - "${MINIO_API_PORT:-9000}:9000"
      - "${MINIO_CONSOLE_PORT:-9001}:9001"
    networks:
      - rag-internal
      - rag-frontend   # Console доступен через NPM
    healthcheck:
      test: ["CMD-SHELL", "mc ready local || exit 1"]
      interval: 15s
      timeout: 10s
      retries: 5
      start_period: 20s
```


---

## 10. RAG — Infinity (эмбеддер + реранкер)

> **Образ:** `michaelf34/infinity:latest` — MIT. Два инстанса: один для эмбеддингов, второй для реранкинга. CPU-режим: флаг `--device cpu`. Модели кешируются в томе `models-cache`.
>
> **CPU-выбор моделей:** `Qwen3-Embedding-0.6B` (0.6B, 1024-dim, 32K context, Apache 2.0) быстрее на CPU, чем `BGE-M3` (568M, но тяжелее). Для реранкера: `bge-reranker-v2-m3` (оптимален без GPU).

```yaml
  # ──────────────────────────────────────────────────────────────
  # INFINITY EMBEDDING SERVER (MIT)
  # Модель: Qwen3-Embedding-0.6B | CPU
  # Port: 7997 | OpenAI-compatible API
  # ──────────────────────────────────────────────────────────────
  embedding:
    <<: *restart
    <<: *logging
    image: ${INFINITY_IMAGE:-michaelf34/infinity:latest}
    container_name: rag-embedding
    command: >
      v2
      --model-name-or-path ${EMBED_MODEL:-Qwen/Qwen3-Embedding-0.6B}
      --served-model-name ${EMBED_SERVED_NAME:-Qwen3-Embedding-0.6B}
      --port 7997
      --device cpu
      --batch-size 32
    environment:
      HF_ENDPOINT: ${HF_ENDPOINT:-https://huggingface.co}
      HF_HUB_CACHE: /models
    volumes:
      - models-cache:/models
    ports:
      - "${EMBED_PORT:-7997}:7997"
    networks:
      - rag-internal
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:7997/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s  # модель грузится с диска

  # ──────────────────────────────────────────────────────────────
  # INFINITY RERANKER SERVER (MIT)
  # Модель: bge-reranker-v2-m3 | CPU
  # Port: 7998 | OpenAI-compatible API
  # ──────────────────────────────────────────────────────────────
  reranker:
    <<: *restart
    <<: *logging
    image: ${INFINITY_IMAGE:-michaelf34/infinity:latest}
    container_name: rag-reranker
    command: >
      v2
      --model-name-or-path ${RERANK_MODEL:-BAAI/bge-reranker-v2-m3}
      --served-model-name ${RERANK_SERVED_NAME:-bge-reranker-v2-m3}
      --port 7998
      --device cpu
      --batch-size 16
    environment:
      HF_ENDPOINT: ${HF_ENDPOINT:-https://huggingface.co}
      HF_HUB_CACHE: /models
    volumes:
      - models-cache:/models    # Shared cache с embedding
    ports:
      - "${RERANK_PORT:-7998}:7998"
    networks:
      - rag-internal
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:7998/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s
```


---

## 11. RAG — Ollama Server

> **Образ:** `ollama/ollama:latest` — MIT. CPU-only конфигурация (без `deploy.resources.reservations.devices`). Защищён Bearer-токеном через переменную `OLLAMA_API_TOKEN` (поддержка добавлена в Ollama v0.4+).
>
> **После запуска — загрузить модели:**
>
> ```bash
> docker exec rag-ollama ollama pull nemotron-3-super:cloud        # основная LLM, сейчас бесплатна
> docker exec rag-ollama ollama pull minimax-m2.7:cloud
> docker exec rag-ollama ollama pull kimi-k2.5:cloud
> ```
>
> 

```yaml
  # ──────────────────────────────────────────────────────────────
  # OLLAMA — сервер локальных LLM (MIT)
  # Port: 11434 | OpenAI-compatible API
  # CPU-only: без gpu device reservations
  # ──────────────────────────────────────────────────────────────
  ollama:
    <<: *restart
    <<: *logging
    image: ${OLLAMA_IMAGE:-ollama/ollama:latest}
    container_name: rag-ollama
    environment:
      OLLAMA_HOST: 0.0.0.0
      OLLAMA_ORIGINS: "*"
      OLLAMA_API_TOKEN: ${OLLAMA_API_TOKEN}
      OLLAMA_NUM_PARALLEL: 2
      OLLAMA_MAX_LOADED_MODELS: 2
      OLLAMA_KEEP_ALIVE: 5m
      TZ: ${TZ:-Asia/Almaty}
    volumes:
      - ollama-data:/root/.ollama
    ports:
      - "${OLLAMA_PORT:-11434}:11434"
    networks:
      - rag-internal
    # CPU-only: нет gpu секции
    # Для GPU добавь:
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: all
    #           capabilities: [gpu]
```


---

## 12. RAG — Docling

> **Образ:** `quay.io/ds4sd/docling-serve:latest` — MIT. Парсер документов с GPU-ускорением (опционально). На CPU работает медленнее, но качество таблиц остаётся высоким.

```yaml
  # ──────────────────────────────────────────────────────────────
  # DOCLING — парсер документов (MIT, IBM Research)
  # Port: 5001 | REST API
  # CPU-only: без GPU device
  # ──────────────────────────────────────────────────────────────
  docling:
    <<: *restart
    <<: *logging
    image: ${DOCLING_IMAGE:-quay.io/ds4sd/docling-serve:latest}
    container_name: rag-docling
    environment:
      DOCLING_SERVE_LOG_LEVEL: INFO
      DOCLING_SERVE_MAX_SYNC_WORKERS: 2
      # CPU-only (без CUDA)
      TORCH_DEVICE: cpu
    volumes:
      - docling-cache:/tmp/docling
    ports:
      - "${DOCLING_PORT:-5001}:5001"
    networks:
      - rag-internal
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:5001/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s
```


---

## 13. RAG — LightRAG

> **Образ:** `ghcr.io/hkuds/lightrag:latest` — MIT. GraphRAG движок. Использует **общие** PostgreSQL (KV + doc status + vector), Neo4j (graph), Qdrant (vectors), Redis (KV кеш). Workspace=`lightrag` для изоляции данных от других сервисов.
>
> **Важно:** LightRAG должен стартовать **после** Neo4j (он коннектится при запуске). Healthcheck Neo4j важен.

```yaml
  # ──────────────────────────────────────────────────────────────
  # LIGHTRAG — GraphRAG движок (MIT, HKUDS)
  # Port: 9621 | REST API + WebUI
  # Хранилище: PG (KV+vector) + Neo4j (graph) + Qdrant (vectors)
  # ──────────────────────────────────────────────────────────────
  lightrag:
    <<: *restart
    <<: *logging
    image: ${LIGHTRAG_IMAGE:-ghcr.io/hkuds/lightrag:latest}
    container_name: rag-lightrag
    env_file:
      - ./configs/lightrag/.env.lightrag
    environment:
      # LLM
      LLM_BINDING: ${LIGHTRAG_LLM_BINDING:-openai}
      LLM_BINDING_HOST: ${LIGHTRAG_LLM_BINDING_HOST:-http://ollama:11434/v1}
      LLM_MODEL: ${LIGHTRAG_LLM_MODEL:-qwen3:14b}
      LLM_BINDING_API_KEY: ${LIGHTRAG_LLM_API_KEY:-ollama}
      # Embedding
      EMBEDDING_BINDING: ${LIGHTRAG_EMBEDDING_BINDING:-openai}
      EMBEDDING_BINDING_HOST: ${LIGHTRAG_EMBEDDING_BINDING_HOST:-http://embedding:7997/v1}
      EMBEDDING_MODEL: ${LIGHTRAG_EMBEDDING_MODEL:-Qwen3-Embedding-0.6B}
      EMBEDDING_DIM: ${LIGHTRAG_EMBEDDING_DIM:-1024}
      # Storage backends
      LIGHTRAG_KV_STORAGE: PGKVStorage
      LIGHTRAG_DOC_STATUS_STORAGE: PGDocStatusStorage
      LIGHTRAG_VECTOR_STORAGE: QdrantVectorDBStorage
      LIGHTRAG_GRAPH_STORAGE: Neo4JStorage
      # PostgreSQL (общий сервер, база lightrag)
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DATABASE: lightrag
      POSTGRES_WORKSPACE: ${LIGHTRAG_WORKSPACE:-lightrag}
      # Redis
      REDIS_URI: redis://:${REDIS_PASSWORD}@redis:6379/3
      # Qdrant
      QDRANT_URL: http://qdrant:6333
      QDRANT_API_KEY: ${QDRANT_API_KEY}
      # Neo4j
      NEO4J_URI: bolt://neo4j:7687
      NEO4J_USERNAME: ${NEO4J_USER:-neo4j}
      NEO4J_PASSWORD: ${NEO4J_PASSWORD}
      # Сервер
      PORT: 9621
      WORKING_DIR: /app/data
      TZ: ${TZ:-Asia/Almaty}
    volumes:
      - lightrag-data:/app/data
    ports:
      - "${LIGHTRAG_PORT:-9621}:9621"
    networks:
      - rag-internal
      - rag-frontend
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      qdrant:
        condition: service_healthy
      neo4j:
        condition: service_healthy
      embedding:
        condition: service_healthy
```

`**configs/lightrag/.env.lightrag**` (дополнительные параметры LightRAG):

```dotenv
# LightRAG расширенная конфигурация
LIGHTRAG_LLM_MAX_ASYNC=4
LIGHTRAG_LLM_MAX_TOKEN=32768
ENABLE_LLM_CACHE=true
CHUNK_SIZE=1200
CHUNK_OVERLAP_TOKEN_SIZE=100
MAX_GRAPH_NODES_IN_CONTEXT=2000
GRAPH_CLUSTER_ALGORITHM=leiden
```


---

## 14. RAG — Mem0

> **Образ:** `mem0ai/mem0-server:latest` — Apache 2.0. Long-term semantic memory для агентов. Хранит факты в PostgreSQL + Qdrant (векторный поиск). 
>
> 
:::warning
> Добавить настройки включения Neo4j для graph memory.
>
> :::

```yaml
  # ──────────────────────────────────────────────────────────────
  # MEM0 — долговременная семантическая память (Apache 2.0)
  # Port: 8888 | REST API
  # Хранилище: PG (metadata) + Qdrant (vectors) + Neo4j (opt graph)
  # ──────────────────────────────────────────────────────────────
  mem0:
    <<: *restart
    <<: *logging
    image: ${MEM0_IMAGE:-mem0ai/mem0-server:latest}
    container_name: rag-mem0
    environment:
      # LLM
      OPENAI_API_KEY: ${OLLAMA_API_TOKEN}
      OPENAI_API_BASE: http://ollama:11434/v1
      # Embedding
      MEM0_EMBEDDER_PROVIDER: ${MEM0_EMBEDDER_PROVIDER:-openai}
      MEM0_EMBEDDER_BASE_URL: ${MEM0_EMBEDDER_BASE_URL:-http://embedding:7997/v1}
      MEM0_EMBEDDER_API_KEY: ${MEM0_EMBEDDER_API_KEY:-infinity}
      MEM0_EMBEDDER_MODEL: ${MEM0_EMBEDDER_MODEL:-Qwen3-Embedding-0.6B}
      # Vector store
      MEM0_VECTOR_STORE_PROVIDER: qdrant
      MEM0_VECTOR_STORE_URL: http://qdrant:6333
      MEM0_VECTOR_STORE_API_KEY: ${QDRANT_API_KEY}
      MEM0_VECTOR_STORE_COLLECTION: mem0_memories
      # PostgreSQL (для истории и метаданных)
      DATABASE_URL: "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/mem0"
      TZ: ${TZ:-Asia/Almaty}
    volumes:
      - mem0-data:/mem0/data
    ports:
      - "${MEM0_PORT:-8888}:8888"
    networks:
      - rag-internal
    depends_on:
      postgres:
        condition: service_healthy
      qdrant:
        condition: service_healthy
      embedding:
        condition: service_healthy
```


---

## 15. RAG — Hindsight

> **Образ:** `ghcr.io/vectorize-io/hindsight:latest` — MIT. Лучшая точность среди open-source memory систем (91.4% LongMemEval). Четыре стратегии ретривала: semantic + BM25 + graph + temporal. API: 8889, WebUI: 9999.
>
> По умолчанию Hindsight запускается с встроенным PostgreSQL (pg0). В нашем стеке переключаем на **внешний PostgreSQL** через `HINDSIGHT_API_DATABASE_URL`.

```yaml
  # ──────────────────────────────────────────────────────────────
  # HINDSIGHT — агентная память #1 по точности (MIT, Vectorize)
  # API: 8889 | WebUI: 9999
  # 4 стратегии: semantic + BM25 + graph + temporal
  # ──────────────────────────────────────────────────────────────
  hindsight:
    <<: *restart
    <<: *logging
    image: ${HINDSIGHT_IMAGE:-ghcr.io/vectorize-io/hindsight:latest}
    container_name: rag-hindsight
    environment:
      # Внешний PostgreSQL (вместо встроенного pg0)
      HINDSIGHT_API_DATABASE_URL: "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/hindsight"
      # LLM (через Ollama)
      HINDSIGHT_API_LLM_PROVIDER: ${HINDSIGHT_API_LLM_PROVIDER:-openai}
      HINDSIGHT_API_LLM_BASE_URL: ${HINDSIGHT_API_LLM_BASE_URL:-http://ollama:11434/v1}
      HINDSIGHT_API_LLM_API_KEY: ${HINDSIGHT_API_LLM_API_KEY:-ollama}
      HINDSIGHT_API_LLM_MODEL: ${HINDSIGHT_API_LLM_MODEL:-qwen3:14b}
      # Embedding (внешний Infinity)
      HINDSIGHT_API_EMBEDDING_PROVIDER: ${HINDSIGHT_API_EMBEDDING_PROVIDER:-openai}
      HINDSIGHT_API_EMBEDDING_BASE_URL: ${HINDSIGHT_API_EMBEDDING_BASE_URL:-http://embedding:7997/v1}
      HINDSIGHT_API_EMBEDDING_API_KEY: ${HINDSIGHT_API_EMBEDDING_API_KEY:-infinity}
      HINDSIGHT_API_EMBEDDING_MODEL: ${HINDSIGHT_API_EMBEDDING_MODEL:-Qwen3-Embedding-0.6B}
      # Reranker (внешний Infinity)
      HINDSIGHT_API_RERANKER_BASE_URL: ${HINDSIGHT_API_RERANKER_BASE_URL:-http://reranker:7998/v1}
      HINDSIGHT_API_RERANKER_MODEL: ${HINDSIGHT_API_RERANKER_MODEL:-bge-reranker-v2-m3}
      TZ: ${TZ:-Asia/Almaty}
    volumes:
      - hindsight-data:/home/hindsight/.hindsight
    ports:
      - "${HINDSIGHT_API_PORT:-8889}:8888"   # API
      - "${HINDSIGHT_UI_PORT:-9999}:9999"    # WebUI
    networks:
      - rag-internal
      - rag-frontend
    depends_on:
      postgres:
        condition: service_healthy
      embedding:
        condition: service_healthy
```


---

## 16. UI — RAGFlow

> **Образ:** `infiniflow/ragflow:v0.26.0` — Apache 2.0. Использует Infinity как document engine (легче Elasticsearch). PostgreSQL вместо MySQL (поддержка с v0.20+). GraphRAG, Memory API, MCP-server, DeepDoc.
>
> **Важно:** RAGFlow имеет сложный стартап-порядок. `depends_on` включает все зависимости. Первый запуск создаёт схему БД самостоятельно.

```yaml
  # ──────────────────────────────────────────────────────────────
  # RAGFLOW — RAG engine + UI (Apache 2.0, InfiniFlow)
  # Web: 8021 | API: 8022
  # Document engine: Infinity (встроенный, не ES)
  # GraphRAG: включён через UI
  # ──────────────────────────────────────────────────────────────
  ragflow:
    <<: *restart
    <<: *logging
    image: ${RAGFLOW_IMAGE:-infiniflow/ragflow:v0.26.0}
    container_name: rag-ragflow
    environment:
      # Document engine — Infinity (lightweight, no Java)
      DOC_ENGINE: ${DOC_ENGINE:-infinity}
      # PostgreSQL вместо MySQL
      DB_TYPE: postgres
      PG_HOST: postgres
      PG_PORT: 5432
      PG_USER: ${POSTGRES_USER}
      PG_PASSWORD: ${POSTGRES_PASSWORD}
      PG_DATABASE: ragflow
      # Redis
      REDIS_HOST: redis
      REDIS_PORT: 6379
      REDIS_PASSWORD: ${REDIS_PASSWORD}
      REDIS_DB: 0
      # MinIO (S3)
      MINIO_HOST: minio
      MINIO_PORT: 9000
      MINIO_USER: ${MINIO_ROOT_USER}
      MINIO_PASSWORD: ${MINIO_ROOT_PASSWORD}
      # TEI Embedding server (Infinity)
      TEI_ENDPOINT: http://embedding:7997
      TEI_MODEL: ${EMBED_SERVED_NAME:-Qwen3-Embedding-0.6B}
      # Timezone
      TZ: ${TZ:-Asia/Almaty}
      SVR_HTTP_PORT: 9380
    volumes:
      - ragflow-data:/ragflow/logs
      - ragflow-data:/ragflow/data
    ports:
      - "${RAGFLOW_PORT:-8021}:80"         # WebUI
      - "${RAGFLOW_API_PORT:-8022}:9380"   # REST API
    networks:
      - rag-internal
      - rag-frontend
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      minio:
        condition: service_healthy
      embedding:
        condition: service_healthy
    # vm.max_map_count=262144 обязателен на хосте
```


---

## 17. UI — Dify

> **Образ:** `langgenius/dify-api:1.4.0` + `dify-web:1.4.0` — Apache 2.0. Визуальный platform для LLM-приложений. Использует PostgreSQL (свою базу `dify`), Redis db:1, Qdrant. Минимальный набор контейнеров для self-hosted.

```yaml
  # ──────────────────────────────────────────────────────────────
  # DIFY API — бэкенд (Apache 2.0, LangGenius)
  # ──────────────────────────────────────────────────────────────
  dify-api:
    <<: *restart
    <<: *logging
    image: ${DIFY_IMAGE:-langgenius/dify-api:1.4.0}
    container_name: rag-dify-api
    environment:
      MODE: api
      SECRET_KEY: ${DIFY_SECRET_KEY}
      # PostgreSQL
      DB_USERNAME: ${POSTGRES_USER}
      DB_PASSWORD: ${POSTGRES_PASSWORD}
      DB_HOST: postgres
      DB_PORT: 5432
      DB_DATABASE: dify
      # Redis
      REDIS_HOST: redis
      REDIS_PORT: 6379
      REDIS_PASSWORD: ${REDIS_PASSWORD}
      REDIS_DB: 1
      CELERY_BROKER_URL: redis://:${REDIS_PASSWORD}@redis:6379/1
      # Vector store
      VECTOR_STORE: qdrant
      QDRANT_URL: http://qdrant:6333
      QDRANT_API_KEY: ${QDRANT_API_KEY}
      # Storage (MinIO / S3)
      STORAGE_TYPE: s3
      S3_ENDPOINT: http://minio:9000
      S3_BUCKET_NAME: dify
      S3_ACCESS_KEY: ${MINIO_ROOT_USER}
      S3_SECRET_KEY: ${MINIO_ROOT_PASSWORD}
      S3_REGION: us-east-1
      # Embedding
      INDEXING_MAX_SEGMENTATION_TOKENS_LENGTH: 1000
      # Mail
      MAIL_TYPE: ${DIFY_MAIL_TYPE:-smtp}
      MAIL_DEFAULT_SEND_FROM: ${DIFY_MAIL_DEFAULT_SEND_FROM:-}
      SMTP_SERVER: ${DIFY_SMTP_SERVER:-}
      SMTP_PORT: ${DIFY_SMTP_PORT:-587}
      SMTP_USERNAME: ${DIFY_SMTP_USERNAME:-}
      SMTP_PASSWORD: ${DIFY_SMTP_PASSWORD:-}
      SMTP_USE_TLS: ${DIFY_SMTP_USE_TLS:-true}
      TZ: ${TZ:-Asia/Almaty}
    volumes:
      - dify-storage:/app/api/storage
    networks:
      - rag-internal
    depends_on:
      <<: *depends-full

  # Dify Worker (Celery)
  dify-worker:
    <<: *restart
    <<: *logging
    image: ${DIFY_IMAGE:-langgenius/dify-api:1.4.0}
    container_name: rag-dify-worker
    environment:
      MODE: worker
      SECRET_KEY: ${DIFY_SECRET_KEY}
      DB_USERNAME: ${POSTGRES_USER}
      DB_PASSWORD: ${POSTGRES_PASSWORD}
      DB_HOST: postgres
      DB_PORT: 5432
      DB_DATABASE: dify
      REDIS_HOST: redis
      REDIS_PORT: 6379
      REDIS_PASSWORD: ${REDIS_PASSWORD}
      REDIS_DB: 1
      CELERY_BROKER_URL: redis://:${REDIS_PASSWORD}@redis:6379/1
      VECTOR_STORE: qdrant
      QDRANT_URL: http://qdrant:6333
      QDRANT_API_KEY: ${QDRANT_API_KEY}
      STORAGE_TYPE: s3
      S3_ENDPOINT: http://minio:9000
      S3_BUCKET_NAME: dify
      S3_ACCESS_KEY: ${MINIO_ROOT_USER}
      S3_SECRET_KEY: ${MINIO_ROOT_PASSWORD}
      S3_REGION: us-east-1
      TZ: ${TZ:-Asia/Almaty}
    volumes:
      - dify-storage:/app/api/storage
    networks:
      - rag-internal
    depends_on:
      <<: *depends-full

  # Dify Sandbox (изолированное выполнение кода)
  dify-sandbox:
    <<: *restart
    <<: *logging
    image: ${DIFY_SANDBOX_IMAGE:-langgenius/dify-sandbox:0.2.10}
    container_name: rag-dify-sandbox
    environment:
      API_KEY: ${DIFY_SECRET_KEY}
      GIN_MODE: release
    networks:
      - rag-internal

  # ──────────────────────────────────────────────────────────────
  # DIFY WEB — фронтенд
  # Port: 8023
  # ──────────────────────────────────────────────────────────────
  dify-web:
    <<: *restart
    <<: *logging
    image: ${DIFY_WEB_IMAGE:-langgenius/dify-web:1.4.0}
    container_name: rag-dify-web
    environment:
      CONSOLE_API_URL: http://dify-api:5001
      APP_API_URL: http://dify-api:5001
      TZ: ${TZ:-Asia/Almaty}
    ports:
      - "${DIFY_PORT:-8023}:3000"
    networks:
      - rag-internal
      - rag-frontend
    depends_on:
      - dify-api
```


---

## 18. UI — Open WebUI

> **Образ:** `ghcr.io/open-webui/open-webui:main` — MIT. ChatGPT-like интерфейс. RAG через ~~Qdrant~~ (9 vector backend поддерживается). Embedding через Infinity по умолчанию (OpenAI-compatible).
>
> 
:::warning
> добавить переменные для выбора qdrant или pgvector, выбора базы и моделей и эмбеддинга из переменных (квен, опенроутер), провайдеров из openai, gemini, qwen, openrouter, ollama. в общем просто прописать все переменные и вынести их в env, как и указано в начале документа.
>
> :::

```yaml
  # ──────────────────────────────────────────────────────────────
  # OPEN WEBUI — чат-интерфейс (MIT)
  # Port: 8024
  # RAG backend: Qdrant | Embedding: Infinity (BGE-M3 / Qwen3)
  # ──────────────────────────────────────────────────────────────
  openwebui:
    <<: *restart
    <<: *logging
    image: ${OPENWEBUI_IMAGE:-ghcr.io/open-webui/open-webui:main}
    container_name: rag-openwebui
    environment:
      # Ollama
      OLLAMA_BASE_URL: http://ollama:11434
      OLLAMA_API_KEY: ${OLLAMA_API_TOKEN}
      # Доп. OpenAI-compatible endpoints (через ; разделитель)
      OPENAI_API_BASE_URLS: "http://ollama:11434/v1"
      OPENAI_API_KEYS: "${OLLAMA_API_TOKEN}"
      # Vector DB
      VECTOR_DB: qdrant
      QDRANT_URI: http://qdrant:6333
      QDRANT_API_KEY: ${QDRANT_API_KEY}
      # RAG Embedding (через Infinity)
      RAG_EMBEDDING_ENGINE: openai
      RAG_EMBEDDING_MODEL: ${EMBED_SERVED_NAME:-Qwen3-Embedding-0.6B}
      RAG_OPENAI_API_BASE_URL: http://embedding:7997/v1
      RAG_OPENAI_API_KEY: infinity
      # Reranker
      RAG_RERANKING_MODEL: ${RERANK_SERVED_NAME:-bge-reranker-v2-m3}
      # PostgreSQL (для auth, чатов, настроек)
      DATABASE_URL: "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/openwebui"
      # Auth
      WEBUI_SECRET_KEY: ${OPENWEBUI_SECRET_KEY}
      # SMTP
      SMTP_HOST: ${OPENWEBUI_SMTP_SERVER:-}
      SMTP_PORT: ${OPENWEBUI_SMTP_PORT:-587}
      SMTP_USERNAME: ${OPENWEBUI_SMTP_USERNAME:-}
      SMTP_PASSWORD: ${OPENWEBUI_SMTP_PASSWORD:-}
      SMTP_SENDER_EMAIL: ${OPENWEBUI_SMTP_FROM:-}
      TZ: ${TZ:-Asia/Almaty}
    volumes:
      - openwebui-data:/app/backend/data
    ports:
      - "${OPENWEBUI_PORT:-8024}:8080"
    networks:
      - rag-internal
      - rag-frontend
    depends_on:
      postgres:
        condition: service_healthy
      qdrant:
        condition: service_healthy
      ollama:
        condition: service_started
      embedding:
        condition: service_healthy
```


---

## 19. UI — AnythingLLM

> **Образ:** `mintplexlabs/anythingllm:latest` — MIT. Workspace-based document management. No-code agent builder с MCP. ~~Qdrant как vector store.~~
>
> 
:::warning
> выбор векторстора и всего остального
>
> :::

```yaml
  # ──────────────────────────────────────────────────────────────
  # ANYTHINGLLM — enterprise document workspace (MIT)
  # Port: 8025
  # Vector: Qdrant | LLM: Ollama | Embed: Infinity
  # ──────────────────────────────────────────────────────────────
  anythingllm:
    <<: *restart
    <<: *logging
    image: ${ANYTHINGLLM_IMAGE:-mintplexlabs/anythingllm:latest}
    container_name: rag-anythingllm
    environment:
      # JWT / Auth
      JWT_SECRET: ${ANYTHINGLLM_JWT_SECRET}
      AUTH_TOKEN: ${ANYTHINGLLM_JWT_SECRET}
      # LLM (Ollama)
      LLM_PROVIDER: ollama
      OLLAMA_BASE_PATH: http://ollama:11434
      OLLAMA_MODEL_PREF: qwen3:14b
      OLLAMA_MODEL_TOKEN_LIMIT: 32768
      # Embedding (Infinity / OpenAI-compatible)
      EMBEDDING_ENGINE: openai
      EMBEDDING_BASE_PATH: http://embedding:7997/v1
      OPEN_AI_KEY: infinity
      EMBEDDING_MODEL_PREF: ${EMBED_SERVED_NAME:-Qwen3-Embedding-0.6B}
      EMBEDDING_MODEL_MAX_CHUNK_LENGTH: 8192
      # Vector store
      VECTOR_DB: qdrant
      QDRANT_ENDPOINT: http://qdrant:6333
      QDRANT_API_KEY: ${QDRANT_API_KEY}
      # Storage
      STORAGE_DIR: ${ANYTHINGLLM_STORAGE_DIR:-/app/server/storage}
      TZ: ${TZ:-Asia/Almaty}
    volumes:
      - anythingllm-data:/app/server/storage
    ports:
      - "${ANYTHINGLLM_PORT:-8025}:3001"
    networks:
      - rag-internal
      - rag-frontend
    depends_on:
      qdrant:
        condition: service_healthy
      ollama:
        condition: service_started
      embedding:
        condition: service_healthy
```


---

## 20. CMS — NocoDB

> **Образ:** `nocodb/nocodb:latest` — AGPL-3.0. Airtable-альтернатива на PostgreSQL. No-code UI для управления таблицами. REST + GraphQL API из любой таблицы.

```yaml
  # ──────────────────────────────────────────────────────────────
  # NOCODB — Airtable-альтернатива (AGPL-3.0)
  # Port: 8026
  # Backend: PostgreSQL (база nocodb)
  # ──────────────────────────────────────────────────────────────
  nocodb:
    <<: *restart
    <<: *logging
    image: ${NOCODB_IMAGE:-nocodb/nocodb:latest}
    container_name: rag-nocodb
    environment:
      NC_DB: "pg://postgres:5432?u=${POSTGRES_USER}&p=${POSTGRES_PASSWORD}&d=${NOCODB_DB:-nocodb}"
      NC_AUTH_JWT_SECRET: ${NOCODB_SECRET}
      NC_REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379/6
      NC_SMTP_FROM: ${DIRECTUS_EMAIL_FROM:-}
      NC_SMTP_HOST: ${DIRECTUS_EMAIL_SMTP_HOST:-}
      NC_SMTP_PORT: ${DIRECTUS_EMAIL_SMTP_PORT:-587}
      NC_SMTP_USERNAME: ${DIRECTUS_EMAIL_SMTP_USER:-}
      NC_SMTP_PASSWORD: ${DIRECTUS_EMAIL_SMTP_PASSWORD:-}
      NC_DISABLE_TELE: "true"
      TZ: ${TZ:-Asia/Almaty}
    volumes:
      - nocodb-data:/usr/app/data
    ports:
      - "${NOCODB_PORT:-8026}:8080"
    networks:
      - rag-internal
      - rag-frontend
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
```


---

## 21. CMS — Directus

> **Образ:** `directus/directus:11` — BSL 1.1 (self-hosted бесплатно). Headless CMS + Data Platform. Работает поверх существующей PostgreSQL-схемы. REST + GraphQL API автоматически из любой таблицы.

```yaml
  # ──────────────────────────────────────────────────────────────
  # DIRECTUS — Headless CMS (BSL 1.1, self-hosted free)
  # Port: 8027
  # Backend: PostgreSQL (база directus) + Redis (cache)
  # ──────────────────────────────────────────────────────────────
  directus:
    <<: *restart
    <<: *logging
    image: ${DIRECTUS_IMAGE:-directus/directus:11}
    container_name: rag-directus
    environment:
      SECRET: ${DIRECTUS_SECRET}
      # PostgreSQL
      DB_CLIENT: pg
      DB_HOST: postgres
      DB_PORT: 5432
      DB_DATABASE: ${DIRECTUS_DB:-directus}
      DB_USER: ${POSTGRES_USER}
      DB_PASSWORD: ${POSTGRES_PASSWORD}
      # Redis (cache)
      CACHE_ENABLED: "true"
      CACHE_STORE: redis
      REDIS: "redis://:${REDIS_PASSWORD}@redis:6379/6"
      # Storage (MinIO / S3)
      STORAGE_LOCATIONS: s3
      STORAGE_S3_DRIVER: s3
      STORAGE_S3_KEY: ${MINIO_ROOT_USER}
      STORAGE_S3_SECRET: ${MINIO_ROOT_PASSWORD}
      STORAGE_S3_BUCKET: directus
      STORAGE_S3_ENDPOINT: http://minio:9000
      STORAGE_S3_FORCE_PATH_STYLE: "true"
      STORAGE_S3_REGION: us-east-1
      # Admin
      ADMIN_EMAIL: ${DIRECTUS_ADMIN_EMAIL}
      ADMIN_PASSWORD: ${DIRECTUS_ADMIN_PASSWORD}
      # Email
      EMAIL_FROM: ${DIRECTUS_EMAIL_FROM:-}
      EMAIL_TRANSPORT: smtp
      EMAIL_SMTP_HOST: ${DIRECTUS_EMAIL_SMTP_HOST:-}
      EMAIL_SMTP_PORT: ${DIRECTUS_EMAIL_SMTP_PORT:-587}
      EMAIL_SMTP_USER: ${DIRECTUS_EMAIL_SMTP_USER:-}
      EMAIL_SMTP_PASSWORD: ${DIRECTUS_EMAIL_SMTP_PASSWORD:-}
      EMAIL_SMTP_SECURE: ${DIRECTUS_EMAIL_SMTP_SECURE:-false}
      TZ: ${TZ:-Asia/Almaty}
      PUBLIC_URL: http://localhost:${DIRECTUS_PORT:-8027}
    volumes:
      - directus-uploads:/directus/uploads
    ports:
      - "${DIRECTUS_PORT:-8027}:8055"
    networks:
      - rag-internal
      - rag-frontend
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      minio:
        condition: service_healthy
```


---

## 22. CMS — Teable

> **Образ:** `ghcr.io/teableio/teable:latest` — AGPL-3.0. Современная Airtable-альтернатива с spreadsheet UI. Нативный PostgreSQL backend — прямой доступ к данным. Оставляем для внутреннего использования

```yaml
  # ──────────────────────────────────────────────────────────────
  # TEABLE — современная spreadsheet-база (AGPL-3.0)
  # Port: 8028
  # Backend: PostgreSQL (база teable)
  # ──────────────────────────────────────────────────────────────
  teable:
    <<: *restart
    <<: *logging
    image: ${TEABLE_IMAGE:-ghcr.io/teableio/teable:latest}
    container_name: rag-teable
    environment:
      PRISMA_DATABASE_URL: "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${TEABLE_DB:-teable}"
      SECRET_KEY: ${TEABLE_SECRET}
      PUBLIC_ORIGIN: ${TEABLE_PUBLIC_ORIGIN:-http://localhost:8028}
      # Storage (MinIO)
      BACKEND_STORAGE_PROVIDER: s3
      BACKEND_STORAGE_S3_REGION: us-east-1
      BACKEND_STORAGE_S3_ENDPOINT: http://minio:9000
      BACKEND_STORAGE_S3_ACCESS_KEY: ${MINIO_ROOT_USER}
      BACKEND_STORAGE_S3_SECRET_KEY: ${MINIO_ROOT_PASSWORD}
      BACKEND_STORAGE_S3_BUCKET: teable
      # Redis (cache + session)
      REDIS_HOST: redis
      REDIS_PORT: 6379
      REDIS_PASSWORD: ${REDIS_PASSWORD}
      REDIS_DB: 6
      # Mail
      BACKEND_MAIL_HOST: ${TEABLE_MAIL_HOST:-}
      BACKEND_MAIL_PORT: ${TEABLE_MAIL_PORT:-587}
      BACKEND_MAIL_USERNAME: ${TEABLE_MAIL_USER:-}
      BACKEND_MAIL_PASSWORD: ${TEABLE_MAIL_PASS:-}
      BACKEND_MAIL_SENDER_ADDRESS: ${TEABLE_MAIL_FROM:-}
      TZ: ${TZ:-Asia/Almaty}
    volumes:
      - teable-data:/app/.cache
    ports:
      - "${TEABLE_PORT:-8028}:3000"
    networks:
      - rag-internal
      - rag-frontend
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      minio:
        condition: service_healthy
```


---

## 23. PROXY — Nginx Proxy Manager

> **Образ:** `jc21/nginx-proxy-manager:latest` — MIT. Web UI для управления proxy hosts, SSL (Let's Encrypt), редиректами. Admin UI на порту 8020. HTTP/HTTPS на 80/443.
>
> **Первый вход:** `admin@example.com` / `changeme` → сменить сразу.
>
> **Внутренние адреса** для proxy hosts (упрощённые имена Docker DNS в сети `rag-frontend`):
>
> * `ragflow:80`, `dify-web:3000`, `openwebui:8080`, `anythingllm:3001`
> * `nocodb:8080`, `directus:8055`, `teable:3000`
> * `lightrag:9621`, `hindsight:9999`, `minio:9001`

```yaml
  # ──────────────────────────────────────────────────────────────
  # NGINX PROXY MANAGER — reverse proxy + SSL (MIT)
  # Admin UI: 8020 | HTTP: 80 | HTTPS: 443
  # ──────────────────────────────────────────────────────────────
  npm-db:
    <<: *restart
    <<: *logging
    image: ${NPM_DB_MYSQL_IMAGE:-jc21/mariadb-aria:latest}
    container_name: rag-npm-db
    environment:
      MYSQL_ROOT_PASSWORD: ${NPM_MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${NPM_MYSQL_DATABASE:-npm}
      MYSQL_USER: ${NPM_MYSQL_USER:-npm}
      MYSQL_PASSWORD: ${NPM_MYSQL_PASSWORD}
    volumes:
      - npm-mysql:/var/lib/mysql
    networks:
      - rag-frontend
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  nginx-proxy-manager:
    <<: *restart
    <<: *logging
    image: ${NPM_IMAGE:-jc21/nginx-proxy-manager:latest}
    container_name: rag-npm
    environment:
      DB_MYSQL_HOST: npm-db
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: ${NPM_MYSQL_USER:-npm}
      DB_MYSQL_PASSWORD: ${NPM_MYSQL_PASSWORD}
      DB_MYSQL_NAME: ${NPM_MYSQL_DATABASE:-npm}
      TZ: ${TZ:-Asia/Almaty}
    volumes:
      - npm-data:/data
      - npm-letsencrypt:/etc/letsencrypt
    ports:
      - "${NPM_HTTP_PORT:-80}:80"           # HTTP (внешний)
      - "${NPM_HTTPS_PORT:-443}:443"        # HTTPS (внешний)
      - "${NPM_ADMIN_PORT:-8020}:81"        # Admin WebUI
    networks:
      - rag-frontend
    depends_on:
      npm-db:
        condition: service_healthy
```


---

## 24. Схема портов

### Хостовые порты (предлагаемая схема для открытия сервисов наружу) Не нуждаются в прописывании в docker-compose.yml при использовании proxymanager

| Порт | Сервис | Назначение |
|----|----|----|
| **80** | Nginx Proxy Manager | HTTP (внешний трафик) |
| **443** | Nginx Proxy Manager | HTTPS (Let's Encrypt) |
| **8020** | NPM Admin UI | Управление proxy / SSL |
| **8021** | RAGFlow Web | Основной RAG UI |
| **8022** | RAGFlow API | REST API (9380 internal) |
| **8023** | Dify | LLM workflow builder |
| **8024** | Open WebUI | Chat interface |
| **8025** | AnythingLLM | Document workspace |
| **8026** | NocoDB | No-code table UI |
| **8027** | Directus | Headless CMS |
| **8028** | Teable | Spreadsheet UI |
| **8029** | LightRAG | GraphRAG API + UI |
| **8030** | Hindsight UI | Memory browser |
| **8031** | Hindsight API | Memory REST API |
| **8032** | Mem0 | Agent memory API |
| **8033** | Docling | Document parser API |
| **8034** | Infinity Embedding | Embedding server |
| **8035** | Infinity Reranker | Reranker server |
| **8036** | Ollama | LLM server |
| **8037** | PostgreSQL | БД (dev доступ) |
| **8038** | Redis/Valkey | Cache (dev доступ) |
| **8039** | Qdrant REST | Vector DB |
| **8040** | Qdrant gRPC | Vector DB |
| **8041** | Neo4j HTTP | Graph DB browser |
| **8042** | Neo4j Bolt | Graph DB driver |
| **8043** | MinIO API | S3-совместимый API |
| **8044** | MinIO Console | Web UI |

### Внутренние адреса (только внутри rag-internal сети)

```
postgres:5432     redis:6379        qdrant:6333
neo4j:7687        minio:9000        embedding:7997
reranker:7998     ollama:11434      docling:5001
lightrag:9621     mem0:8888         hindsight:8888
```


---

## 25. Init SQL (PostgreSQL)

`**configs/postgres/init.sql**`


:::warning
исправить локаль на локаль из переменной POSTGRES_LOCALE
Добавить схему как 
`entrypoint: - sh - -c - | cat << 'EOF' > /docker-entrypoint-initdb.d/init.sql` 
в раздел postgres compose

:::

```sql
-- ================================================================
-- PostgreSQL инициализация для RAG Sandbox
-- Выполняется при первом старте контейнера
-- ================================================================

-- Extensions (на базе ragdb)
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_bm25;
CREATE EXTENSION IF NOT EXISTS vectorscale;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ----------------------------------------------------------------
-- Создание баз данных для каждого сервиса
-- ----------------------------------------------------------------
SELECT 'CREATE DATABASE ragflow   ENCODING ''UTF8'' LC_COLLATE ''ru_RU.UTF-8'' LC_CTYPE ''ru_RU.UTF-8'' TEMPLATE template0'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ragflow')\gexec

SELECT 'CREATE DATABASE dify      ENCODING ''UTF8'' LC_COLLATE ''ru_RU.UTF-8'' LC_CTYPE ''ru_RU.UTF-8'' TEMPLATE template0'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'dify')\gexec

SELECT 'CREATE DATABASE openwebui ENCODING ''UTF8'' LC_COLLATE ''ru_RU.UTF-8'' LC_CTYPE ''ru_RU.UTF-8'' TEMPLATE template0'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'openwebui')\gexec

SELECT 'CREATE DATABASE lightrag  ENCODING ''UTF8'' LC_COLLATE ''ru_RU.UTF-8'' LC_CTYPE ''ru_RU.UTF-8'' TEMPLATE template0'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'lightrag')\gexec

SELECT 'CREATE DATABASE mem0      ENCODING ''UTF8'' LC_COLLATE ''ru_RU.UTF-8'' LC_CTYPE ''ru_RU.UTF-8'' TEMPLATE template0'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'mem0')\gexec

SELECT 'CREATE DATABASE hindsight ENCODING ''UTF8'' LC_COLLATE ''ru_RU.UTF-8'' LC_CTYPE ''ru_RU.UTF-8'' TEMPLATE template0'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'hindsight')\gexec

SELECT 'CREATE DATABASE directus  ENCODING ''UTF8'' LC_COLLATE ''ru_RU.UTF-8'' LC_CTYPE ''ru_RU.UTF-8'' TEMPLATE template0'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'directus')\gexec

SELECT 'CREATE DATABASE nocodb    ENCODING ''UTF8'' LC_COLLATE ''ru_RU.UTF-8'' LC_CTYPE ''ru_RU.UTF-8'' TEMPLATE template0'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'nocodb')\gexec

SELECT 'CREATE DATABASE teable    ENCODING ''UTF8'' LC_COLLATE ''ru_RU.UTF-8'' LC_CTYPE ''ru_RU.UTF-8'' TEMPLATE template0'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'teable')\gexec

-- ----------------------------------------------------------------
-- Extensions в каждой базе (pgvector нужен везде)
-- ----------------------------------------------------------------
\c ragflow
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

\c dify
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

\c openwebui
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

\c lightrag
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

\c mem0
CREATE EXTENSION IF NOT EXISTS vector;

\c hindsight
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

\c directus
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

\c nocodb
-- (без extensions)

\c teable
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ----------------------------------------------------------------
-- Вернуться в основную БД
-- ----------------------------------------------------------------
\c ragdb

-- ----------------------------------------------------------------
-- Пример: shared таблица для собственного Retrieval API
-- (опционально — для кастомных пайплайнов поверх стека)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS shared_chunks (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id     TEXT NOT NULL,               -- оригинальный документ
    chunk_index   INT NOT NULL,
    content       TEXT NOT NULL,
    embedding     VECTOR(1024),                -- Qwen3-Embedding-0.6B dim
    metadata      JSONB DEFAULT '{}',
    source_type   TEXT,                        -- pdf / docx / url / etc
    language      TEXT DEFAULT 'ru',
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- HNSW index для косинусного поиска (pgvector)
CREATE INDEX IF NOT EXISTS shared_chunks_embedding_idx
    ON shared_chunks USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- BM25 индекс (pg_bm25 / ParadeDB)
CREATE INDEX IF NOT EXISTS shared_chunks_bm25_idx
    ON shared_chunks
    USING bm25 (id, content, metadata)
    WITH (key_field='id', text_fields='{"content": {"tokenizer": {"type": "icu"}}}');

-- Full-text GIN для ru_RU
CREATE INDEX IF NOT EXISTS shared_chunks_fts_idx
    ON shared_chunks
    USING gin (to_tsvector('russian', content));

-- Тригграммный индекс для fuzzy поиска
CREATE INDEX IF NOT EXISTS shared_chunks_trgm_idx
    ON shared_chunks USING gin (content gin_trgm_ops);
```


---

## 26. Сборка минимального стека

Примеры готовых конфигураций по копипасту.

### Минимальный (только БД + эмбеддер + один UI)

```bash
# Блоки для включения:
# 4 (общая часть) + 5 + 6 + 7 + 9 + 10 + 11 + 18
# Итого: PG + Redis + Qdrant + MinIO + Embedding + Ollama + OpenWebUI
```

### Полный production стек

```bash
# Все блоки 4–23
# Команда запуска:
docker compose up -d

# Порядок запуска (автоматически через depends_on):
# 1. postgres, redis, qdrant, neo4j, minio
# 2. embedding, reranker, ollama, docling
# 3. lightrag, mem0, hindsight
# 4. ragflow, dify-api, dify-worker, dify-sandbox
# 5. openwebui, anythingllm, nocodb, directus, teable
# 6. nginx-proxy-manager
```

### Полезные команды

```bash
# Загрузка моделей Ollama после старта
docker exec rag-ollama ollama pull qwen3:14b
docker exec rag-ollama ollama pull qwen3:1.7b
docker exec rag-ollama ollama pull nomic-embed-text

# Проверка статуса всех сервисов
docker compose ps

# Логи конкретного сервиса
docker compose logs -f lightrag
docker compose logs -f ragflow

# Рестарт одного сервиса
docker compose restart hindsight

# Полная пересборка с новыми образами
docker compose pull && docker compose up -d

# Бэкап PostgreSQL
docker exec rag-postgres pg_dumpall -U ragadmin > backup_$(date +%Y%m%d).sql

# Проверка Qdrant коллекций
curl -H "api-key: $QDRANT_API_KEY" http://localhost:6333/collections

# Проверка Hindsight
curl http://localhost:8031/health

# Проверка LightRAG
curl http://localhost:8029/health
```


---

## 27. Дополнение: LiteLLM Proxy

LiteLLM — унифицированный OpenAI-compatible прокси над 100+ LLM провайдерами. Все платформы видят **один endpoint** и переключают модели через `model` параметр.


:::warning
убрать прокидывание локального файла, оно не сработает в портейнер. вписать конфиг текстом прямо в компоуз файл. 

:::

```yaml
  # ──────────────────────────────────────────────────────────────
  # LITELLM PROXY — унифицированный LLM gateway (MIT)
  # Port: 4000 | OpenAI-compatible API
  # ──────────────────────────────────────────────────────────────
  litellm:
    restart: unless-stopped
    image: ghcr.io/berriai/litellm:main-latest
    container_name: rag-litellm
    environment:
      # Мастер-ключ для доступа к proxy
      LITELLM_MASTER_KEY: ${LITELLM_MASTER_KEY}
      # Провайдеры
      OPENROUTER_API_KEY: ${OPENROUTER_API_KEY}
      GEMINI_API_KEY: ${GEMINI_API_KEY}
      QWEN_API_KEY: ${QWEN_API_KEY}
      KIMI_API_KEY: ${KIMI_API_KEY}
      MINIMAX_API_KEY: ${MINIMAX_API_KEY}
      HF_TOKEN: ${HF_TOKEN}
    volumes:
      - ./configs/litellm/config.yaml:/app/config.yaml
    command: ["--config", "/app/config.yaml", "--port", "4000"]
    ports:
      - "4000:4000"
    networks:
      - rag-internal
```

`**configs/litellm/config.yaml**`**~~:~~**

```yaml
model_list:
  # Локальные через Ollama
  - model_name: qwen3:14b
    litellm_params:
      model: ollama/qwen3:14b
      api_base: http://ollama:11434

  - model_name: qwen3:1.7b
    litellm_params:
      model: ollama/qwen3:1.7b
      api_base: http://ollama:11434

  # Облачные через OpenRouter
  - model_name: nemotron-3-super
    litellm_params:
      model: openrouter/nvidia/llama-3.1-nemotron-70b-instruct
      api_key: os.environ/OPENROUTER_API_KEY

  - model_name: kimi-k2.5
    litellm_params:
      model: openrouter/moonshotai/kimi-k2
      api_key: os.environ/OPENROUTER_API_KEY

  - model_name: glm-5
    litellm_params:
      model: openrouter/thudm/glm-4-32b
      api_key: os.environ/OPENROUTER_API_KEY

  - model_name: minimax-m2.7
    litellm_params:
      model: openrouter/minimax/minimax-m1-40k
      api_key: os.environ/OPENROUTER_API_KEY

  # Qwen API (Alibaba Cloud)
  - model_name: qwen3.5-cloud
    litellm_params:
      model: openai/qwen-plus
      api_base: https://dashscope.aliyuncs.com/compatible-mode/v1
      api_key: os.environ/QWEN_API_KEY

  # Google Gemini
  - model_name: gemini-2.5-flash
    litellm_params:
      model: gemini/gemini-2.5-flash
      api_key: os.environ/GEMINI_API_KEY

  # Kimi (Moonshot напрямую)
  - model_name: kimi-direct
    litellm_params:
      model: openai/moonshot-v1-128k
      api_base: https://api.moonshot.cn/v1
      api_key: os.environ/KIMI_API_KEY

litellm_settings:
  drop_params: true
  set_verbose: false
  num_retries: 3
  request_timeout: 120

general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
```

**После добавления LiteLLM** можно добавлять endpoint во всех платформах:

* Вместо `http://ollama:11434/v1` → `http://litellm:4000/v1`
* API ключ: значение `OLLAMA_API_TOKEN` (он же `LITELLM_MASTER_KEY`)
* Модели: указывай по именам из `model_name` в config.yaml


---

*RAG Playground Sandbox Guide · Март 2026 · CPU-only · Self-hosted · Open Source*