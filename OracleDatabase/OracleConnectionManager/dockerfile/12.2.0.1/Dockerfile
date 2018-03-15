# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Connection Manager
# 
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) linuxx64_12201_client
#     Download Oracle Connection Manager as part of the Oracle Database Client
#     from http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build -t oracle/cman:12.2.0.1 . 
#
# Pull base image
# ---------------
FROM oraclelinux:7-slim

# Maintainer
# ----------
MAINTAINER Sanjay Singh (Sanjay.Singh@oracle.com), Paramdeep Saini (paramdeep.saini@oracle.com)

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
# Linux Env Variable
ENV SETUP_LINUX_FILE="setupLinuxEnv.sh" \
    INSTALL_DIR=/opt/scripts \
# Grid Env variables
    INVENTORY=/u01/app/oraInventory \
    DB_BASE=/u01/app/oracle \
    DB_HOME=/u01/app/oracle/product/12.2.0/client_1 \
    INSTALL_FILE_1="linuxx64_12201_client.zip" \
    DB_INSTALL_RSP="client.rsp" \
    DB_SETUP_FILE="setupDB.sh" \
    RUN_FILE="runOracle.sh" \
    CONFIG_CMAN_FILE="configCMAN.sh" \
    CHECK_SPACE_FILE="checkSpace.sh" \
    CMANORA="cman.ora" \
    FUNCTIONS="functions.sh" \
    INSTALL_DB_BINARIES_FILE="installDBBinaries.sh" \
    container="true" 
# Use second ENV so that variable get substituted
ENV  INSTALL_SCRIPTS=$INSTALL_DIR/install \
     PATH=/bin:/usr/bin:/sbin:/usr/sbin:$PATH \
     SCRIPT_DIR=$INSTALL_DIR/startup \
     DB_PATH=$DB_HOME/bin:$DB_HOME/OPatch/:/usr/sbin:$PATH \
     DB_LD_LIBRARY_PATH=$DB_HOME/lib:/usr/lib:/lib

# Copy binaries
# -------------
# Grid Binaries
COPY $INSTALL_FILE_1 $SETUP_LINUX_FILE $CHECK_SPACE_FILE $CLIENT_RSP $INSTALL_DB_BINARIES_FILE $INSTALL_DIR/install/

COPY $RUN_FILE $CMANORA $CONFIG_CMAN_FILE $FUNCTIONS $INSTALL_DIR/startup/

RUN chmod 777 $INSTALL_DIR/install/*.sh && \
    sync && \
    $INSTALL_DIR/install/$CHECK_SPACE_FILE && \
    $INSTALL_DIR/install/$SETUP_LINUX_FILE && \
    $INSTALL_DIR/install/$DB_SETUP_FILE 

# Install DB software binaries
USER oracle
RUN $INSTALL_DIR/install/$INSTALL_DB_BINARIES_FILE EE 

USER root
RUN $INVENTORY/orainstRoot.sh && \
    $DB_HOME/root.sh && \
    rm -rf $INSTALL_DIR/install && \
    rm -f /etc/security/limits.d/oracle-database-server-12cR2-preinstall.conf && \
    chown -R oracle:oinstall $SCRIPT_DIR && \
    chmod 755 $SCRIPT_DIR/*.sh && \
    chmod 666 $SCRIPT_DIR/*.ora && \
    sync 

USER  oracle
WORKDIR /home/oracle
EXPOSE 1521 5500

# Define default command to start Oracle Database.
CMD exec $SCRIPT_DIR/$RUN_FILE
