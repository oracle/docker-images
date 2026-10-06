# LICENSE UPL 1.0
#
# Copyright (c) 2014-2024 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Database 18c RAC Storage Server. This file create NFS server for ASM storage. 
# 
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build -t oracle/rac-storage-server:19.3.0. 
#
# Pull base image
# ---------------
ARG BASE_IMAGE=oraclelinux:8
ARG BASE_IMAGE_REF=oraclelinux:8
ARG BASE_IMAGE_DIGEST=unknown
FROM $BASE_IMAGE
ARG BASE_IMAGE
ARG BASE_IMAGE_REF
ARG BASE_IMAGE_DIGEST
LABEL "org.opencontainers.image.base.name"="$BASE_IMAGE_REF" \
      "org.opencontainers.image.base.digest"="$BASE_IMAGE_DIGEST" \
      "com.oracle.database.base.image.chain.path"="/usr/share/oracle/image-metadata/base-image-chain.json"

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
# Linux Env Variable
ENV SETUP_LINUX_FILE="setupLinuxEnv.sh" \
    INSTALL_DIR=/opt/scripts \
    EXPORTFILE=exportfile \
    RUN_FILE="runOracle.sh" \
    SUDO_SETUP_FILE="setupSudo.sh" \
    INITSH="initsh" \
    BIN="/usr/sbin" \
    ORADATA="/oradata" \
    container="true" 
# Use second ENV so that variable get substituted
ENV  INSTALL_SCRIPTS=$INSTALL_DIR/install  \
     SCRIPT_DIR=$INSTALL_DIR/startup

# Copy binaries
# -------------
# Copy Linux setup Files
COPY $SETUP_LINUX_FILE $SUDO_SETUP_FILE $INSTALL_SCRIPTS/

# Setup Scripts
COPY $RUN_FILE $EXPORTFILE $INITSH $SCRIPT_DIR/

RUN  chmod 755 $INSTALL_DIR/install/*.sh && \
     $INSTALL_DIR/install/$SETUP_LINUX_FILE && \
     $INSTALL_DIR/install/$SUDO_SETUP_FILE && \
     sync 
   
RUN  rm -rf $INSTALL_DIR/install && \
    chmod 755 $SCRIPT_DIR/*.sh && \
    echo "nohup $SCRIPT_DIR/runOracle.sh &" >> /etc/rc.local && \
    chmod +x /etc/rc.d/rc.local  && \
    cp $SCRIPT_DIR/$INITSH /usr/bin/$INITSH && \
    chmod 755 /usr/bin/$INITSH && \ 
    chmod 666 $SCRIPT_DIR/$EXPORTFILE

RUN mkdir -p /usr/share/oracle/image-metadata && \
    printf '{\n  "schemaVersion": 1,\n  "images": [{"name": "%s", "digest": "%s", "reference": "%s", "role": "direct-base"}]\n}\n' \
      "$BASE_IMAGE_REF" "$BASE_IMAGE_DIGEST" "$BASE_IMAGE" > /usr/share/oracle/image-metadata/base-image-chain.json

USER root 
VOLUME ["/oradata"]
WORKDIR /workdir

# Define default command to start Oracle Database.
# hadolint ignore=DL3025
ENTRYPOINT /usr/bin/$INITSH
