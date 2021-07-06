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
ARG EXTENSION_NAME=sharding

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
   SHARD_SETUP="false" 

# backup original runOracle
RUN if test -e "$ORACLE_BASE/$RUN_FILE.orig"; then EXTN='extended'; else EXTN='orig'; fi ; \
    mv "$ORACLE_BASE/$RUN_FILE" "$ORACLE_BASE/$RUN_FILE.$EXTN"

# Copy updated scripts for sharding support
COPY  --chown=oracle:dba $CMD_EXEC $DEMO_APP $MAIN_PY $COMMON_PY $ENV_PY $FACTORY_PY $GSM_PY $LOGGER_PY $MACHINE_PY $PCATALOG_PY $SHARD_PY $SCATALOG_PY $SSHARD_PY $RUN_SHARD_FILE $RUN_FILE $ORACLE_BASE/scripts/sharding/
RUN mv "$ORACLE_BASE/scripts/sharding/$RUN_FILE" "$ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME"

# Set perms and append a call to main runOracle
RUN if test -e "$ORACLE_BASE/$RUN_FILE.extended"; then \
        mv "$ORACLE_BASE/$RUN_FILE.extended" "$ORACLE_BASE/$RUN_FILE" ; \
    else echo ". $ORACLE_BASE/$RUN_FILE.orig" > "$ORACLE_BASE/$RUN_FILE" ; fi ; \
    if ! grep "$RUN_FILE.$EXTENSION_NAME" "$ORACLE_BASE/$RUN_FILE"; then \
       sed  -i "\$a . $ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME" "$ORACLE_BASE/$RUN_FILE"; \
    fi && \
    sed -i '/wait \$childPID/d' "$ORACLE_BASE"/runOracle.sh.orig && \ 
    chmod ug+x $ORACLE_BASE/$RUN_FILE $ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME $ORACLE_BASE/scripts/sharding/*.sh $ORACLE_BASE/scripts/sharding/*.py && sync
