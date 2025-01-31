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

ARG BASE_IMAGE_VERSION=23.5.0
ARG BASE_IMAGE=oracle/database-rac:${BASE_IMAGE_VERSION}
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
   PYTHON_FILE="/usr/bin/python" \
   PYTHON3_FILE="/usr/libexec/platform-python3.9" \
   SHARD_SETUP="false" \
   ORACLE_BASE="/opt/oracle" \
   PWD_FILE="setPassword.sh" \
   RAC_IMAGE_RUN_ORACLE_LOC="/opt/scripts/startup" \
   ORACLE_HOME="$DB_HOME"

# Create Soft link and install python3 RPM

USER root
RUN /usr/bin/dnf -y install python3
RUN if [ ! -f $PYTHON_FILE ]; then \
      ln -s $PYTHON3_FILE $PYTHON_FILE && \
      :; \
    fi && \
    sync

RUN mkdir -p $ORACLE_BASE/scripts/sharding/scripts && \
    chown -R oracle:dba $ORACLE_BASE/scripts && \
    sync

# Copy updated scripts for sharding support
COPY  --chown=oracle:dba --from=downloader /tmp/db-sharding/container-based-sharding-deployment/containerfiles/${BASE_IMAGE_VERSION}/scripts/* $ORACLE_BASE/scripts/sharding/

# This is to add the setPassword.sh script
COPY $PWD_FILE $ORACLE_BASE/

RUN chmod ug+x "$ORACLE_BASE"/*.sh && \
    ln -s "$ORACLE_BASE"/"$PWD_FILE" /home/oracle/ && \
    chown oracle:dba "$ORACLE_BASE"/"$PWD_FILE" && \
    mkdir $ORACLE_BASE/oradata && \
    chown oracle:dba $ORACLE_BASE/oradata && \
    sync

RUN mv "$ORACLE_BASE/scripts/sharding/$RUN_FILE" "$ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME" && \
    chmod 755 $ORACLE_BASE/scripts/sharding/* && \
    sync

# Set perms and append a call to main runOracle
# Create a Wrapper Script to call the main sharding->runOracle file as oracle user and append a call to main runOracle
RUN  mv "$RAC_IMAGE_RUN_ORACLE_LOC/$RUN_FILE" "$RAC_IMAGE_RUN_ORACLE_LOC/$RUN_FILE.orig" && \
    echo ". $RAC_IMAGE_RUN_ORACLE_LOC/$RUN_FILE.orig" > "$RAC_IMAGE_RUN_ORACLE_LOC/$RUN_FILE" && \
    echo "#!/bin/bash" > "$ORACLE_BASE/$RUN_FILE.wrapper" && \
    echo "export ORACLE_HOME=\$DB_HOME" >> "$ORACLE_BASE/$RUN_FILE.wrapper" && \
    echo "export COMMON_OS_PWD_FILE=\$DB_PWD_FILE" >> "$ORACLE_BASE/$RUN_FILE.wrapper" && \
    echo "export ORACLE_PDB=\$ORACLE_PDB_NAME" >> "$ORACLE_BASE/$RUN_FILE.wrapper" && \
    echo "export ORACLE_SID=\$DB_NAME" >> "$ORACLE_BASE/$RUN_FILE.wrapper" && \
    echo "/bin/su oracle -c $ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME" >> "$ORACLE_BASE/$RUN_FILE.wrapper" && \
    chmod 755 $ORACLE_BASE/$RUN_FILE.wrapper && \
    sed  -i "\$a . $ORACLE_BASE/$RUN_FILE.wrapper" "$RAC_IMAGE_RUN_ORACLE_LOC/$RUN_FILE" && \
    chmod ug+x $RAC_IMAGE_RUN_ORACLE_LOC/$RUN_FILE $RAC_IMAGE_RUN_ORACLE_LOC/$RUN_FILE.orig $ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME $RAC_IMAGE_RUN_ORACLE_LOC/scripts/*.sh $RAC_IMAGE_RUN_ORACLE_LOC/scripts/*.py $ORACLE_BASE/scripts/sharding/*.sh $ORACLE_BASE/scripts/sharding/*.py && \
    sync
