# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
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
#      $ docker build -t <extended_image_name> . --build-arg BASE_IMAGE=18.3.0-ee
#

ARG BASE_IMAGE=oracle/database:19.3.0-ee
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

# Extn name
ARG EXTENSION_NAME=k8s

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV STARTUP_FILE=startUp.sh \
    SHUT_DB_FILE=shutDown.sh \
    LOCKING_SCRIPT=lock.py \
    SWAP_LOCK_FILE=swapLocks.sh \
    CHECK_DB_LOCK_FILE=checkDBLockStatus.sh \
    EXTENSION_SCRIPT_DIR="/opt/oracle/scripts/extensions/k8s" \
    PYTHONUNBUFFERED=1

# Turn on dnfs
# hadolint ignore=DL3003
RUN cd "$ORACLE_HOME"/rdbms/lib && make -f ins_rdbms.mk dnfs_on

# Updated Health Check
HEALTHCHECK --interval=1m --start-period=15m --timeout=30s \
   CMD "$EXTENSION_SCRIPT_DIR/$CHECK_DB_LOCK_FILE" >/dev/null || exit 1

# backup original runOracle
RUN if test -e "$ORACLE_BASE/$RUN_FILE.orig"; then EXTN='extended'; else EXTN='orig'; fi ; \
    mv "$ORACLE_BASE/$RUN_FILE" "$ORACLE_BASE/$RUN_FILE.$EXTN" && \
    mkdir -p "$EXTENSION_SCRIPT_DIR" "$ORACLE_BASE/scripts/extensions/setup"

# Copy updated scripts for k8s support 
COPY  --chown=oracle:dba $RUN_FILE $START_FILE $STARTUP_FILE $SHUT_DB_FILE $LOCKING_SCRIPT $CHECK_DB_LOCK_FILE $SWAP_LOCK_FILE $EXTENSION_SCRIPT_DIR/

# Set perms and append a call to main runOracle
RUN if test -e "$ORACLE_BASE/$RUN_FILE.extended"; then \
        mv "$ORACLE_BASE/$RUN_FILE.extended" "$ORACLE_BASE/$RUN_FILE" ; \
    else echo ". $ORACLE_BASE/$RUN_FILE.orig" > "$ORACLE_BASE/$RUN_FILE" ; fi ; \
    printf '#!/bin/bash\n# shellcheck source=/dev/null\n. "%s/%s"\n' "$EXTENSION_SCRIPT_DIR" "$RUN_FILE" > "$ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME" && \
    for script in "$START_FILE" "$STARTUP_FILE" "$SHUT_DB_FILE" "$LOCKING_SCRIPT" "$CHECK_DB_LOCK_FILE"; do \
        printf '#!/bin/bash\nexec "%s/%s" "$@"\n' "$EXTENSION_SCRIPT_DIR" "$script" > "$ORACLE_BASE/$script"; \
    done && \
    printf '#!/bin/bash\nexec "%s/%s" "$@"\n' "$EXTENSION_SCRIPT_DIR" "$SWAP_LOCK_FILE" > "$ORACLE_BASE/scripts/extensions/setup/$SWAP_LOCK_FILE" && \
    ln -sf "$EXTENSION_SCRIPT_DIR/$STARTUP_FILE" /home/oracle/ && \
    ln -sf "$EXTENSION_SCRIPT_DIR/$SHUT_DB_FILE" /home/oracle/ && \
    if ! grep "$RUN_FILE.$EXTENSION_NAME" "$ORACLE_BASE/$RUN_FILE"; then \
        sed  -i "1i . $ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME" "$ORACLE_BASE/$RUN_FILE"; \
    fi && \
    chmod ug+x "$ORACLE_BASE"/*.sh "$ORACLE_BASE"/scripts/extensions/setup/*.sh "$ORACLE_BASE"/*.py "$EXTENSION_SCRIPT_DIR"/*.sh "$EXTENSION_SCRIPT_DIR"/*.py && sync
