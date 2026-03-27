#!/bin/sh
###############################################################################
#  docker-entrypoint.sh — prepare Caddyfile and start Caddy
#
#  Reads CADDY_TLS_MODE from the environment:
#    off      (default) — plain HTTP, auto_https off
#    auto     — Let's Encrypt ACME (requires CADDY_HOST + CADDY_EMAIL)
#    internal — Caddy internal CA, self-signed (good for local HTTPS testing)
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
# Render template
# ---------------------------------------------------------------------------
envsubst < /etc/caddy/Caddyfile.tmpl > /etc/caddy/Caddyfile

exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile "$@"
