# LICENSE UPL 1.0
#
# Copyright (c) 2021 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Database with Fast Fail Over support
#
# REQUIREMETNS FOR THIS IMAGE
# ----------------------------------
# Any release of prebuilt oracle/database base docker image
#
# HOW TO BUILD THIS IMAGE
# -----------------------
#
# Run:
#      $ docker build -t <extended_image_name> . --build-arg BASE_IMAGE=oracle/database:19.3.0-ee
#

ARG BASE_IMAGE_VERSION=19.3.0
ARG BASE_IMAGE=oracle/database:${BASE_IMAGE_VERSION}-ee
ARG BASE_REPO=https://github.com/oracle/db-sharding

# Creating stage for downloading necessary script files
FROM ${BASE_IMAGE} as downloader
ARG BASE_REPO
ENV BASE_REPO=$BASE_REPO
WORKDIR /tmp

USER root
RUN yum -y install git && \
    git clone --depth=1 ${BASE_REPO}

# Creating another stage for sharding extension creation
FROM ${BASE_IMAGE}
# Extn name
ARG EXTENSION_NAME=sharding
ARG BASE_IMAGE_VERSION

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV CMD_EXEC="cmdExec" \
   DEMO_APP="demoapp.sql" \
   MAIN_PY="main.py" \
   COMMON_PY="oracommon.py" \
   ENV_PY="oraenv.py" \
   FACTORY_PY="orafactory.py" \
   GSM_PY="oragsm.py" \
   LOGGER_PY="oralogger.py" \
   MACHINE_PY="oramachine.py" \
   PCATALOG_PY="orapcatalog.py" \
   SHARD_PY="orapshard.py" \
   SCATALOG_PY="orascatalog.py" \
   SSHARD_PY="orasshard.py" \
   RUN_SHARD_FILE="runOraShardSetup.sh" \
   RUN_FILE="runOracle.sh" \
   SHARD_SCRIPT_DIR="/opt/oracle/scripts/sharding" \
   PYTHON_FILE="/usr/bin/python" \
   PYTHON3_FILE="/usr/libexec/platform-python3.6" \
   SHARD_SETUP="false"

# Create Soft link and install python3 RPM

USER root
RUN yum -y install python3
RUN if [ ! -f $PYTHON_FILE ]; then \
      ln -s $PYTHON3_FILE $PYTHON_FILE && \
      :; \
    fi && \
    sync

# backup original runOracle
USER oracle
RUN BASE_RUN_DIR="${SCRIPT_BASE_DIR:-$ORACLE_BASE}" ; \
    if test -e "$BASE_RUN_DIR/$RUN_FILE.orig"; then EXTN='extended'; else EXTN='orig'; fi ; \
    mv "$BASE_RUN_DIR/$RUN_FILE" "$BASE_RUN_DIR/$RUN_FILE.$EXTN"

RUN mkdir -p "$SHARD_SCRIPT_DIR/scripts" && \
    chown -R oracle:dba "$ORACLE_BASE/scripts" && \
    sync

# Copy updated scripts for sharding support
COPY  --chown=oracle:dba --from=downloader /tmp/db-sharding/container-based-sharding-deployment/containerfiles/scripts/* $SHARD_SCRIPT_DIR/
RUN BASE_RUN_DIR="${SCRIPT_BASE_DIR:-$ORACLE_BASE}" && \
    mv "$SHARD_SCRIPT_DIR/$RUN_FILE" "$BASE_RUN_DIR/$RUN_FILE.$EXTENSION_NAME" && \
    if [ "$BASE_RUN_DIR" != "$ORACLE_BASE" ]; then \
      printf '#!/bin/bash\n# shellcheck source=/dev/null\n. "%s/%s.%s"\n' "$BASE_RUN_DIR" "$RUN_FILE" "$EXTENSION_NAME" > "$ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME"; \
    fi && \
    chmod 755 "$SHARD_SCRIPT_DIR"/* && \
    sync

# Set perms and append a call to main runOracle
RUN BASE_RUN_DIR="${SCRIPT_BASE_DIR:-$ORACLE_BASE}" ; \
    if test -e "$BASE_RUN_DIR/$RUN_FILE.extended"; then \
        mv "$BASE_RUN_DIR/$RUN_FILE.extended" "$BASE_RUN_DIR/$RUN_FILE" ; \
    else echo ". $BASE_RUN_DIR/$RUN_FILE.orig" > "$BASE_RUN_DIR/$RUN_FILE" ; fi ; \
    if ! grep "$RUN_FILE.$EXTENSION_NAME" "$BASE_RUN_DIR/$RUN_FILE"; then \
       sed  -i "\$a . $BASE_RUN_DIR/$RUN_FILE.$EXTENSION_NAME" "$BASE_RUN_DIR/$RUN_FILE"; \
    fi && \
    sed -i '/alert.log/,$ s/wait \$childPID//' "$BASE_RUN_DIR/$RUN_FILE.orig" && \
    chmod ug+x $BASE_RUN_DIR/$RUN_FILE $BASE_RUN_DIR/$RUN_FILE.$EXTENSION_NAME "$SHARD_SCRIPT_DIR"/*.sh "$SHARD_SCRIPT_DIR"/*.py && \
    if [ "$BASE_RUN_DIR" != "$ORACLE_BASE" ]; then chmod ug+x "$ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME"; fi && \
    chown oracle:dba $BASE_RUN_DIR/$RUN_FILE && \
    sync
