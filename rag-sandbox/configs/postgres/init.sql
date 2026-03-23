-- =============================================================================
-- PostgreSQL initialization script for RAG Sandbox
-- Creates extensions in the default ragdb database and provisions per-service
-- databases with the extensions each service requires.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Extensions in the default database (ragdb)
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ---------------------------------------------------------------------------
-- 2. Create per-service databases (idempotent via \gexec pattern)
-- ---------------------------------------------------------------------------
SELECT 'CREATE DATABASE ragflow'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ragflow')\gexec

SELECT 'CREATE DATABASE dify'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'dify')\gexec

SELECT 'CREATE DATABASE openwebui'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'openwebui')\gexec

SELECT 'CREATE DATABASE lightrag'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'lightrag')\gexec

SELECT 'CREATE DATABASE mem0'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'mem0')\gexec

SELECT 'CREATE DATABASE hindsight'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'hindsight')\gexec

SELECT 'CREATE DATABASE directus'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'directus')\gexec

SELECT 'CREATE DATABASE nocodb'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'nocodb')\gexec

SELECT 'CREATE DATABASE teable'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'teable')\gexec

SELECT 'CREATE DATABASE langfuse'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'langfuse')\gexec

SELECT 'CREATE DATABASE pipelines'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'pipelines')\gexec

-- ---------------------------------------------------------------------------
-- 3. Create extensions in each service database
-- ---------------------------------------------------------------------------

-- ragflow: vector search + trigram similarity + accent-insensitive search
\c ragflow
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- dify: vector search + trigram similarity
\c dify
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- openwebui: vector search + trigram similarity
\c openwebui
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- lightrag: vector search + trigram similarity + uuid generation
\c lightrag
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- mem0: vector search
\c mem0
CREATE EXTENSION IF NOT EXISTS vector;

-- hindsight: vector search + trigram similarity
\c hindsight
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- directus: uuid generation
\c directus
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- nocodb: no extra extensions needed
\c nocodb

-- teable: uuid generation
\c teable
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- langfuse: uuid generation
\c langfuse
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ---------------------------------------------------------------------------
-- 4. Return to the default ragdb database
-- ---------------------------------------------------------------------------
\c ragdb

-- ---------------------------------------------------------------------------
-- 5. Example table: shared_chunks
--    Demonstrates vector storage with HNSW index, Russian full-text search
--    via GIN index, and trigram index for fuzzy matching.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS shared_chunks (
    id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    source      TEXT NOT NULL,
    content     TEXT NOT NULL,
    embedding   VECTOR(1024),
    metadata    JSONB DEFAULT '{}',
    created_at  TIMESTAMPTZ DEFAULT now()
);

-- HNSW index for approximate nearest-neighbour vector search
CREATE INDEX IF NOT EXISTS idx_shared_chunks_embedding
    ON shared_chunks
    USING hnsw (embedding vector_cosine_ops);

-- GIN index for Russian full-text search on content
CREATE INDEX IF NOT EXISTS idx_shared_chunks_fts_ru
    ON shared_chunks
    USING gin (to_tsvector('russian', content));

-- GIN trigram index for fuzzy / LIKE / ILIKE queries on content
CREATE INDEX IF NOT EXISTS idx_shared_chunks_trgm
    ON shared_chunks
    USING gin (content gin_trgm_ops);
