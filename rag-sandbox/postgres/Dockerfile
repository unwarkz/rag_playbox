ARG PG_BASE=pgvector/pgvector:pg17
FROM ${PG_BASE}
ARG POSTGRES_LOCALE
RUN localedef -i ${POSTGRES_LOCALE%%.*} -c -f ${POSTGRES_LOCALE##*.} -A /usr/share/locale/locale.alias ${POSTGRES_LOCALE}
ENV LANG ${POSTGRES_LOCALE}