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
FROM ${BASE_IMAGE}

# Extn name
ARG EXTENSION_NAME=k8s

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV ORACLE_SID=ORCLCDB \
    STARTUP_FILE=startUp.sh \
    SHUT_DB_FILE=shutDown.sh \
    LOCKING_SCRIPT=lock.py \
    SWAP_LOCK_FILE=swapLocks.sh \
    CHECK_DB_LOCK_FILE=checkDBLockStatus.sh

# Turn on dnfs
RUN cd $ORACLE_HOME/rdbms/lib && make -f ins_rdbms.mk dnfs_on

# Updated Health Check
HEALTHCHECK --interval=1m --start-period=30m \
   CMD "$ORACLE_BASE/$CHECK_DB_LOCK_FILE" >/dev/null || exit 1

# backup original runOracle
RUN if test -e "$ORACLE_BASE/$RUN_FILE.orig"; then EXTN='extended'; else EXTN='orig'; fi ; \
    mv "$ORACLE_BASE/$RUN_FILE" "$ORACLE_BASE/$RUN_FILE.$EXTN" && \
    ln -sf "$ORACLE_BASE/$STARTUP_FILE" /home/oracle/ && \
    ln -sf "$ORACLE_BASE/$SHUT_DB_FILE" /home/oracle/

# Copy updated scripts for k8s support 
COPY  --chown=oracle:dba $RUN_FILE $START_FILE $STARTUP_FILE $SHUT_DB_FILE $LOCKING_SCRIPT $CHECK_DB_LOCK_FILE $ORACLE_BASE/
RUN   mv "$ORACLE_BASE/$RUN_FILE" "$ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME"
COPY  --chown=oracle:dba $SWAP_LOCK_FILE $ORACLE_BASE/scripts/extensions/setup/

# Set perms and append a call to main runOracle
RUN if test -e "$ORACLE_BASE/$RUN_FILE.extended"; then \
        mv "$ORACLE_BASE/$RUN_FILE.extended" "$ORACLE_BASE/$RUN_FILE" ; \
    else echo ". $ORACLE_BASE/$RUN_FILE.orig" > "$ORACLE_BASE/$RUN_FILE" ; fi ; \
    if ! grep "$RUN_FILE.$EXTENSION_NAME" "$ORACLE_BASE/$RUN_FILE"; then \
        sed  -i "1i . $ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME" "$ORACLE_BASE/$RUN_FILE"; \
    fi && \
    chmod ug+x $ORACLE_BASE/*.sh $ORACLE_BASE/*.py && sync
