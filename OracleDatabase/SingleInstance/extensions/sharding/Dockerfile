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
FROM oraclelinux:7-slim as downloader
ARG BASE_REPO
ENV BASE_REPO=$BASE_REPO
WORKDIR /tmp

RUN yum -y install gzip tar && \
    curl -L -o master.tar.gz ${BASE_REPO}/archive/master.tar.gz && \
    tar -xvf master.tar.gz

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
   SHARD_SETUP="false"

# backup original runOracle
RUN if test -e "$ORACLE_BASE/$RUN_FILE.orig"; then EXTN='extended'; else EXTN='orig'; fi ; \
    mv "$ORACLE_BASE/$RUN_FILE" "$ORACLE_BASE/$RUN_FILE.$EXTN"

# Copy updated scripts for sharding support
COPY  --chown=oracle:dba --from=downloader /tmp/db-sharding-master/docker-based-sharding-deployment/dockerfiles/${BASE_IMAGE_VERSION}/scripts/* $ORACLE_BASE/scripts/sharding/
RUN mv "$ORACLE_BASE/scripts/sharding/$RUN_FILE" "$ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME"

# Set perms and append a call to main runOracle
RUN if test -e "$ORACLE_BASE/$RUN_FILE.extended"; then \
        mv "$ORACLE_BASE/$RUN_FILE.extended" "$ORACLE_BASE/$RUN_FILE" ; \
    else echo ". $ORACLE_BASE/$RUN_FILE.orig" > "$ORACLE_BASE/$RUN_FILE" ; fi ; \
    if ! grep "$RUN_FILE.$EXTENSION_NAME" "$ORACLE_BASE/$RUN_FILE"; then \
       sed  -i "\$a . $ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME" "$ORACLE_BASE/$RUN_FILE"; \
    fi && \
    sed -i '/alert.log/,$ s/wait \$childPID//' "$ORACLE_BASE"/runOracle.sh.orig && \
    chmod ug+x $ORACLE_BASE/$RUN_FILE $ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME $ORACLE_BASE/scripts/sharding/*.sh $ORACLE_BASE/scripts/sharding/*.py && sync