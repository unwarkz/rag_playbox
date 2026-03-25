###############################################################################
#                    RAG SANDBOX - ENV FILES INDEX
#                         March 2026
###############################################################################

# ORGANIZATION
===============================================================================
All environment variables have been split into organized .env files by category.
Load these files in your docker-compose.yml using the 'env_file:' directive.

Example:
  services:
    postgres:
      env_file:
        - env/general.env
        - env/docker.env
        - env/postgres.env
        - env/email.env


# CATEGORY BREAKDOWN
===============================================================================

## CORE CONFIGURATION (Load in all docker-compose files)
  general.env              - Basic settings (TZ, stack name, project name)
  docker.env               - Docker config (restart policy, logging, limits, images, networks)

## SECURITY & KEYS
  api-keys.env             - External provider API keys (OpenAI, Anthropic, Gemini, etc.)
  email.env                - SMTP configuration (shared across services)
  host-ports.env           - Optional SSH tunnel port mappings (dev/testing only)


## DATA LAYER SERVICES (Databases & Storage)
  postgres.env             - PostgreSQL + pgvector
                             • Admin: ragadmin / Ch4ng3me_P0stgres!
                             • Per-service DB users & passwords
                             • Database names
  
  redis.env                - Redis/Valkey cache
                             • Root password
                             • Per-service Redis users & passwords
  
  qdrant.env               - Qdrant vector database
                             • API key
                             • REST/gRPC ports
  
  neo4j.env                - Neo4j graph database
                             • Admin credentials
                             • Ports & JVM heap
  
  minio.env                - S3-compatible object storage
                             • Root credentials
                             • Default bucket


## AI/ML LAYER SERVICES
  infinity.env             - Embedding & Reranker server
                             • Infinity API key
                             • Model configs (Qwen/BAAI models)
  
  ollama.env               - Local LLM inference
                             • Port & host config
                             • Model list (Qwen3:14b, Qwen3:1.7b)
                             • Performance tuning


## DOCUMENT PROCESSING
  docling.env              - Document parsing (DS4SD)
  tika.env                 - Apache Tika extraction
  unstructured.env         - Unstructured document processing


## RAG ENGINES
  lightrag.env             - LightRAG (graph-augmented RAG)
                             • LLM & embedding bindings
                             • Storage backends (PG, Qdrant, Neo4j)
  
  mem0.env                 - Mem0 (semantic memory)
  hindsight.env            - Hindsight (agent memory & timeline)
  ragflow.env              - RAGFlow (RAG platform)


## APPLICATION PLATFORMS
  dify.env                 - Dify LLM Platform (API, Worker, Sandbox, Web)
                             • Database & Redis connections
                             • Storage (MinIO S3)
                             • Code execution endpoint
  
  openwebui.env            - Open WebUI chat interface
  openwebui-pipelines.env  - Open WebUI function pipelines
  anythingllm.env          - AnythingLLM document workspace


## DATA MANAGEMENT PLATFORMS
  nocodb.env               - NocoDB (Airtable alternative)
  directus.env             - Directus (headless CMS)
  teable.env               - Teable (spreadsheet database)


## INFRASTRUCTURE
  npm.env                  - Nginx Proxy Manager (reverse proxy + SSL)
                             • HTTP/HTTPS/Admin ports
                             • MariaDB credentials


## OBSERVABILITY
  litellm.env              - LiteLLM (unified LLM proxy)
                             • Master key for rate limiting
                             • Langfuse integration
  
  langfuse.env             - Langfuse (LLM observability & tracing)
                             • Initial org/project/user setup
  
  dbhub.env                - DBHub (database MCP server)


# USAGE PATTERNS
===============================================================================

1. FULL STACK (all 30 environment files):
   env_file:
     - env/general.env
     - env/docker.env
     - env/api-keys.env
     - env/postgres.env
     - env/redis.env
     - env/qdrant.env
     - env/neo4j.env
     - env/minio.env
     - env/infinity.env
     - env/ollama.env
     - env/docling.env
     - env/tika.env
     - env/unstructured.env
     - env/lightrag.env
     - env/mem0.env
     - env/hindsight.env
     - env/ragflow.env
     - env/dify.env
     - env/openwebui.env
     - env/openwebui-pipelines.env
     - env/anythingllm.env
     - env/nocodb.env
     - env/directus.env
     - env/teable.env
     - env/npm.env
     - env/litellm.env
     - env/langfuse.env
     - env/dbhub.env
     - env/email.env
     - env/host-ports.env

2. MINIMAL RAG STACK (core only):
   env_file:
     - env/general.env
     - env/docker.env
     - env/postgres.env
     - env/redis.env
     - env/qdrant.env
     - env/minio.env
     - env/ollama.env
     - env/infinity.env
     - env/ragflow.env
     - env/email.env

3. LLM + RAG (with Dify/Open WebUI):
   env_file:
     - env/general.env
     - env/docker.env
     - env/postgres.env
     - env/redis.env
     - env/qdrant.env
     - env/minio.env
     - env/ollama.env
     - env/infinity.env
     - env/dify.env
     - env/openwebui.env
     - env/email.env


# SECURITY NOTES
===============================================================================

⚠️  ALL PASSWORDS carry the pattern "Ch4ng3me_*"
    → Change them before production use!

⚠️  API_KEYS are all placeholders:
    → Replace with real values from:
       • OpenAI Dashboard
       • Anthropic Console
       • OpenRouter
       • Google Gemini
       • Alibaba Qwen (DashScope)
       • HuggingFace
       • Moonshot Kimi
       • MiniMax

⚠️  Nginx Proxy Manager (NPM)
    → First login credentials: admin@example.com / changeme
    → MUST be changed immediately after first login

⚠️  Do not commit these files to version control with real secrets.
    → Use a secrets management solution (Vault, SecretsManager, etc.)


# ENVIRONMENT VARIABLE GROUPS
===============================================================================

By Database/Service:
  • postgres.env        - 11 variables (admin + 10 service DBs)
  • redis.env          - 15 variables (password + 7 service users)
  • qdrant.env         - 4 variables
  • neo4j.env          - 8 variables
  • minio.env          - 5 variables
  • infinity.env       - 8 variables (shared API key)
  • ollama.env         - 6 variables
  • docling.env        - 4 variables
  • tika.env           - 2 variables
  • unstructured.env   - 2 variables
  • lightrag.env       - 12 variables
  • mem0.env           - 9 variables
  • hindsight.env      - 6 variables
  • ragflow.env        - 15 variables
  • dify.env           - 26 variables (API, Worker, Sandbox, Web)
  • openwebui.env      - 9 variables
  • openwebui-pipelines.env  - 2 variables
  • anythingllm.env    - 12 variables
  • nocodb.env         - 6 variables
  • directus.env       - 16 variables
  • teable.env         - 7 variables
  • npm.env            - 7 variables
  • litellm.env        - 12 variables
  • langfuse.env       - 15 variables
  • dbhub.env          - 2 variables
  • docker.env         - 30+ variables (limits, images, logging, networks)
  • general.env        - 3 variables
  • email.env          - 7 variables
  • api-keys.env       - 18+ variables
  • host-ports.env     - 10 variables


# TOTAL VARIABLES: 350+
===============================================================================

This modular structure allows:
  ✓ Easy service management (update only what's needed)
  ✓ Clear separation of concerns
  ✓ Flexible docker-compose configurations
  ✓ Audit trail (which env files were used for which deployment)
  ✓ Templating for different environments (dev, staging, prod)
  ✓ Secret rotation without touching the main .env file


###############################################################################
#                         NEXT STEPS
###############################################################################

1. Update passwords in service-specific files:
   - Change all "Ch4ng3me_*" values
   - Use strong, unique passwords per service

2. Add real API keys to api-keys.env:
   - OpenAI, Anthropic, etc.
   - Provider-specific configuration

3. Configure email settings in email.env:
   - SMTP host, port, credentials
   - Sender addresses

4. Update docker-compose to reference these files:
   Example: env_file: [env/general.env, env/docker.env, ...]

5. (Optional) Set up host-ports.env for SSH tunneling to databases

6. Deploy and monitor!

###############################################################################
