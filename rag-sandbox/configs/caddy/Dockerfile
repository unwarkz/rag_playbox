###############################################################################
#  configs/caddy/Dockerfile
#
#  Builds a Caddy binary that includes the layer4 plugin for raw-TCP proxying
#  (PostgreSQL, Redis, Qdrant gRPC, Neo4j Bolt).
#
#  Stage 1 — xcaddy: compiles caddy + mholt/caddy-l4
#  Stage 2 — runtime: standard caddy:latest with the custom binary swapped in
#             and gettext added for envsubst (Caddyfile template rendering).
###############################################################################

FROM caddy:builder AS builder

RUN xcaddy build \
    --with github.com/mholt/caddy-l4@latest

# ---------------------------------------------------------------------------

FROM caddy:latest

# gettext provides envsubst — used by docker-entrypoint.sh to render the
# Caddyfile template before starting Caddy.
RUN apk add --no-cache gettext

# Replace the stock caddy binary with our layer4-enabled build.
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
