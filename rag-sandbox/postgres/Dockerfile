ARG PG_BASE=pgvector/pgvector:pg17
FROM ${PG_BASE}

ARG POSTGRES_LOCALE=ru_RU.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends locales \
    && sed -i "/${POSTGRES_LOCALE}/s/^# //" /etc/locale.gen \
    && locale-gen \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*
