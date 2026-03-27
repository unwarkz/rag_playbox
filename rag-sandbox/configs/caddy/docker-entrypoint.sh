#!/bin/sh
###############################################################################
#  docker-entrypoint.sh — prepare Caddyfile and start Caddy
#
#  Reads CADDY_TLS_MODE from the environment:
#    off      (default) — plain HTTP, auto_https off
#    auto     — Let's Encrypt ACME (requires CADDY_HOST + CADDY_EMAIL)
#    internal — Caddy internal CA, self-signed (good for local HTTPS testing)
#
#  Reads OLLAMA_BEARER_TOKEN from the environment:
#    (empty)  — Ollama proxy port (8036) is open, no authentication required
#    <token>  — Caddy enforces  Authorization: Bearer <token>  on port 8036
#               Internal service calls to ollama:11434 are never affected.
#
#  Reads QDRANT_API_KEY from the environment:
#    (empty)  — Qdrant proxy port (8039) forwards requests as-is
#    <key>    — Caddy injects  Authorization: Bearer <key>  on every upstream
#               request to Qdrant, so the /dashboard opens without prompting
#               the user to enter the key manually.
#
#  Renders /etc/caddy/Caddyfile.tmpl → /etc/caddy/Caddyfile via envsubst,
#  then execs caddy.
###############################################################################
set -e

# ---------------------------------------------------------------------------
# TLS-mode directives
# ---------------------------------------------------------------------------
case "${CADDY_TLS_MODE:-off}" in
    auto|acme)
        if [ -z "${CADDY_EMAIL:-}" ]; then
            echo "ERROR: CADDY_EMAIL must be set when CADDY_TLS_MODE=auto" >&2
            exit 1
        fi
        CADDY_AUTO_HTTPS_DIRECTIVE=""
        CADDY_TLS_DIRECTIVE="tls ${CADDY_EMAIL}"
        ;;
    internal)
        CADDY_AUTO_HTTPS_DIRECTIVE=""
        CADDY_TLS_DIRECTIVE="tls internal"
        ;;
    *)
        # off — or any unrecognised value
        CADDY_AUTO_HTTPS_DIRECTIVE="auto_https off"
        CADDY_TLS_DIRECTIVE=""
        ;;
esac

export CADDY_AUTO_HTTPS_DIRECTIVE CADDY_TLS_DIRECTIVE

# ---------------------------------------------------------------------------
# Optional email directive (only relevant for ACME/Let's Encrypt)
# ---------------------------------------------------------------------------
if [ -n "${CADDY_EMAIL:-}" ]; then
    CADDY_EMAIL_DIRECTIVE="email ${CADDY_EMAIL}"
else
    CADDY_EMAIL_DIRECTIVE=""
fi

export CADDY_EMAIL_DIRECTIVE

# ---------------------------------------------------------------------------
# Ollama bearer-token auth (proxy port only; internal port 11434 unchanged)
# When OLLAMA_BEARER_TOKEN is set, Caddy returns 401 for any request that
# does not include  Authorization: Bearer <token>.
# ---------------------------------------------------------------------------
if [ -n "${OLLAMA_BEARER_TOKEN:-}" ]; then
    CADDY_OLLAMA_AUTH_MATCHER="@ollama_unauth not header Authorization \"Bearer ${OLLAMA_BEARER_TOKEN}\""
    CADDY_OLLAMA_AUTH_RESPOND="respond @ollama_unauth 401"
else
    CADDY_OLLAMA_AUTH_MATCHER=""
    CADDY_OLLAMA_AUTH_RESPOND=""
fi

export CADDY_OLLAMA_AUTH_MATCHER CADDY_OLLAMA_AUTH_RESPOND

# ---------------------------------------------------------------------------
# Qdrant API key header injection
# When QDRANT_API_KEY is set, Caddy adds  Authorization: Bearer <key>  to
# every upstream request so the /dashboard opens without a manual key entry.
# ---------------------------------------------------------------------------
if [ -n "${QDRANT_API_KEY:-}" ]; then
    CADDY_QDRANT_AUTH_HEADER="header_up Authorization \"Bearer ${QDRANT_API_KEY}\""
else
    CADDY_QDRANT_AUTH_HEADER=""
fi

export CADDY_QDRANT_AUTH_HEADER

# ---------------------------------------------------------------------------
# Render template
# ---------------------------------------------------------------------------
envsubst < /etc/caddy/Caddyfile.tmpl > /etc/caddy/Caddyfile

exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile "$@"
