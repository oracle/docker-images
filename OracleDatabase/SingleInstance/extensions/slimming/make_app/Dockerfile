# LICENSE UPL 1.0
#
# Copyright (c) 2018, 2022 Oracle and/or its affiliates.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle NanoVOS
# 
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) Nanovos Parameter file (ex. tkinnvos1.ora)
# (2) Nanovos library (ex. libhelloworld.so)
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#  $ podman build -t nanovos-app . --build-arg PARAM_FILE=<param_file> --build-arg NANOVOS_LIB=<lib_name> --format=docker
#
# Pull base image
# ---------------
FROM oracle/nanovos:26.0.0 as base

# Labels
# ------
LABEL "provider"="Oracle"                                               \
      "port.listener"="1521"                                            

ARG PARAM_FILE
ARG NANOVOS_LIB

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV ORACLE_BASE=/opt/oracle \
    ORACLE_HOME=/opt/oracle/product/26ai/dbhome_1 \
    RUN_FILE="runNanovos.sh" \
    START_FILE="startInstance.sh" \
    PARAM_FILE=$PARAM_FILE

# Use second ENV so that variable get substituted
ENV PATH=$ORACLE_HOME/bin:/usr/sbin:$PATH \
    LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib

USER oracle

COPY --chown=oracle:dba $RUN_FILE $START_FILE $PARAM_FILE $NANOVOS_LIB $ORACLE_BASE

WORKDIR /home/oracle

# Add a bashrc file to capitalize ORACLE_SID in the environment
RUN echo 'ORACLE_SID=${ORACLE_SID:-ORCLCDB}; export ORACLE_SID=${ORACLE_SID^^}' > .bashrc

# Define default command to start Nanovos Instance. 
CMD [ "/bin/bash", "-c", "$ORACLE_BASE/$RUN_FILE" ]
