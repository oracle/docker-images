# Copyright (c) 2022, 2023 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
#
FROM ghcr.io/graalvm/jdk:ol8-java17

LABEL org.opencontainers.image.source = "https://github.com/oracle/docker-images"

ARG KV_VERSION=22.3.32
ARG DOWNLOAD_ROOT=http://download.oracle.com/otn-pub/otn_software/nosql-database
ARG DOWNLOAD_FILE="kv-ce-${KV_VERSION}.zip"
ARG DOWNLOAD_LINK="${DOWNLOAD_ROOT}/${DOWNLOAD_FILE}"

ENV KV_PROXY_PORT 8080
ENV KV_ADMIN_PORT 5999

ENV KV_PORT 5000
ENV KV_HARANGE 5010-5020
ENV KV_SERVICERANGE 5021-5049

# hadolint ignore=DL4006
RUN useradd -d /kvroot  -m -s /bin/bash -u 1000 nosql-user && \
    chown -R nosql-user /app/

USER nosql-user

WORKDIR "/app"

# hadolint ignore=DL4006
RUN curl -OLs $DOWNLOAD_LINK && \
    jar tf $DOWNLOAD_FILE | grep "kv-$KV_VERSION/lib" > extract.libs && \
    jar xf $DOWNLOAD_FILE @extract.libs && \
    rm -f $DOWNLOAD_FILE extract.libs

WORKDIR "/app/kv-$KV_VERSION"

COPY --chown=nosql-user start-kvlite.sh .
RUN chmod +x start-kvlite.sh

VOLUME ["/kvroot"]

CMD ["bash", "-c", "./start-kvlite.sh"]
