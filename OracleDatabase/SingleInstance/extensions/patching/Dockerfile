# LICENSE UPL 1.0
#
# Copyright (c) 1982-2023 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Database with patching support
#
# REQUIREMETNS FOR THIS IMAGE
# ----------------------------------
#
#
# HOW TO BUILD THIS IMAGE
# -----------------------
#
# Run:
#      $ docker build -t <extended_image_name> . --build-arg BASE_IMAGE=oracle/database:18.3.0-ee
#
# Pull base image
# ---------------
ARG BASE_IMAGE=oracle/database:19.3.0-ee
# hadolint ignore=DL3006
FROM ${BASE_IMAGE} as patching

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV HOST_PATCH_DIR="patches" \
    PATCH_DIR=/opt/install/patches \
    PATCH_DB_BINARIES_FILE="patchDBBinaries.sh"

# Copy DB patches
COPY --chown=oracle:dba $HOST_PATCH_DIR $PATCH_DB_BINARIES_FILE $PATCH_DIR/

# Apply DB Patch
RUN chmod ug+x $PATCH_DIR/*.sh && \
    sync && \
    $PATCH_DIR/$PATCH_DB_BINARIES_FILE && \
    rm -rf $PATCH_DIR/* $ORACLE_HOME/.patch_storage $ORACLE_HOME/.opatchauto_storage


## New stage for minimal layer size
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}-base
ENV DATAPATCH_FILE="runDatapatch.sh" \
    LSPATCHES_FILE="savePatchSummary.sh" \
    SKIP_DATAPATCH=false \
    STARTUP_FILE=startUp.sh \
    SHUT_DB_FILE=shutDown.sh \
    LOCKING_SCRIPT=lock.py \
    SWAP_LOCK_FILE=swapLocks.sh \
    CHECK_DB_LOCK_FILE=checkDBLockStatus.sh

USER oracle
WORKDIR /home/oracle

# Copying patched oracle_base from previous layer
COPY --from=patching $ORACLE_BASE $ORACLE_BASE

# Copy script to run datapatch
COPY --chown=oracle:dba $DATAPATCH_FILE $ORACLE_BASE/scripts/extensions/startup/
RUN chmod ug+x "$ORACLE_BASE"/scripts/extensions/startup/*.sh && sync

# Copy script to run lspatches
COPY --chown=oracle:dba $LSPATCHES_FILE $ORACLE_BASE/scripts/extensions/setup/
# hadolint ignore=SC2016
RUN chmod ug+x "$ORACLE_BASE"/scripts/extensions/setup/*.sh && sync && \
    echo 'ORACLE_SID=${ORACLE_SID:-ORCLCDB}; export ORACLE_SID=${ORACLE_SID^^}' > .bashrc

USER root
RUN "$ORACLE_BASE"/oraInventory/orainstRoot.sh && \
    "$ORACLE_HOME"/root.sh

USER oracle

# Using checkDBLockStatus.sh if k8s extension was applied, otherwise, using checkDBStatus.sh
HEALTHCHECK --interval=1m --start-period=20m --timeout=30s \
   CMD if [ -e $ORACLE_BASE/$CHECK_DB_LOCK_FILE ]; then $ORACLE_BASE/$CHECK_DB_LOCK_FILE ; else $ORACLE_BASE/$CHECK_DB_FILE ; fi >/dev/null || exit 1

# Define default command to start Oracle Database. 
CMD [ "/bin/bash", "-c", "exec $ORACLE_BASE/$RUN_FILE" ]
