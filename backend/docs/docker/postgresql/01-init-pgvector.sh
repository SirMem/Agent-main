#!/bin/sh
set -eu

SCHEMA_NAME="${EMBEDDING_SCHEMA_NAME:-public}"
TABLE_NAME="${EMBEDDING_TABLE_NAME:-vector_store_openai}"
DIMENSIONS="${EMBEDDING_DIMENSIONS:-1024}"

psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<EOF
CREATE EXTENSION IF NOT EXISTS vector;
CREATE SCHEMA IF NOT EXISTS "${SCHEMA_NAME}";
CREATE TABLE IF NOT EXISTS "${SCHEMA_NAME}"."${TABLE_NAME}" (
    id uuid PRIMARY KEY,
    content text,
    metadata json,
    embedding vector(${DIMENSIONS})
);
CREATE INDEX IF NOT EXISTS embedding_idx
    ON "${SCHEMA_NAME}"."${TABLE_NAME}"
    USING hnsw (embedding vector_cosine_ops);
EOF
