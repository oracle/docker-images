# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Database 12c Release 2 RAC Storage Server. This file create NFS server for ASM storage. 
# 
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build -t oracle/rac-storage-server:12.2.0.1. 
#
# Pull base image
# ---------------
FROM oraclelinux:7-slim

# Maintainer
# ----------
MAINTAINER Paramdeep saini <paramdeep.saini@oracle.com>, Sanjay Singh <sanjay.singh@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
# Linux Env Variable
ENV SETUP_LINUX_FILE="setupLinuxEnv.sh" \
    INSTALL_DIR=/opt/scripts \
    EXPORTFILE=exportfile \
    RUN_FILE="runOracle.sh" \
    SUDO_SETUP_FILE="setupSudo.sh" \
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
COPY $RUN_FILE $EXPORTFILE $SCRIPT_DIR/

RUN  chmod 777 $INSTALL_DIR/install/*.sh && \
     $INSTALL_DIR/install/$SETUP_LINUX_FILE && \
     $INSTALL_DIR/install/$SUDO_SETUP_FILE && \
     sync 
   
RUN  rm -rf $INSTALL_DIR/install && \
    chmod 755 $SCRIPT_DIR/*.sh && \
    chmod 666 $SCRIPT_DIR/$EXPORTFILE

USER  oracle
VOLUME ["/oradata"]
WORKDIR /home/oracle

# Define default command to start Oracle Database.

CMD exec $SCRIPT_DIR/$RUN_FILE
