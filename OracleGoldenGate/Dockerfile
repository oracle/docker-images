# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 1982-2017 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is a Dockerfile for Oracle GoldenGate 12c Release 1.   It depends upon the 
# Docker image for Oracle Database at: 
# https://github.com/oracle/docker-images/tree/master/OracleDatabase.
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) fbo_ggs_Linux_x64_shiphome.zip
#     
#     Download Oracle GoldenGate 12c Release 1 Enterprise Edition for Linux x64
#     from http://www.oracle.com/technetwork/middleware/goldengate/downloads/index.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ docker build -t 
#
# Pull base image
# ---------------

FROM oracle/database:12.1.0.2-ee

# Maintainer
# ----------
MAINTAINER Rick Michaud<rick.michaud@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV ORACLE_BASE=/opt/oracle 					\
    ORACLE_HOME=/opt/oracle/product/12.1.0.2/dbhome_1 		\
    OGG_INSTALL_FILE="fbo_ggs_Linux_x64_shiphome.zip" 		\
    OGG_INSTALL_RSP="oggcore.rsp"				\
    RUN_FILE="runOracle.sh" 					\
    START_FILE="startDB.sh" 					\
    RUN_FILE="runOracle.sh" 					\
    CREATE_DB_FILE="createDB.sh" 				\
    SETUP_LINUX_FILE="setupLinuxEnv.sh" 			\
    SETUP_LINUX="startDB.sh" 					\
    INSTALL_OGG_FILE="installOGG.sh" 

ENV INSTALL_DIR=$ORACLE_BASE/install 				\
    LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib 			\
    CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib		\
    OGG_INSTALL_DIR=$ORACLE_BASE/ogg 				

# Setup $PATH properly for environment
ENV PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch/:/usr/sbin:$PATH 	\
    PATH=$OGG_INSTALL_DIR:.:$PATH 				\
    GGHOME=$OGG_INSTALL_DIR

# Copy binaries
# -------------
# Copy GoldenGate components to installation directory
COPY $OGG_INSTALL_FILE $OGG_INSTALL_RSP $SETUP_LINUX_FILE $INSTALL_OGG_BINARIES_FILE $INSTALL_DIR/

# Overlay the database creation run script with the one ammended with GoldenGate requirements
COPY $RUN_FILE $CREATE_DB_FILE $ORACLE_BASE/

USER root
RUN chmod ug+x $INSTALL_DIR/*.sh && \
    sync && \
    $INSTALL_DIR/$SETUP_LINUX_FILE

# Setup rlwrap aliases for use with ggsci and SQL*Plus to enable command line completion.
# Note for SQL*Plus you can also use sqlcl locally on your host environment.
USER oracle
RUN $INSTALL_DIR/$INSTALL_OGG_FILE	 			&& \
    echo "alias ggsci='rlwrap ggsci'" >> ~/.bashrc              && \
    echo "alias sqlplus='rlwrap sqlplus'" >> ~/.bashrc

WORKDIR /home/oracle

VOLUME ["$ORACLE_BASE/oradata"]
EXPOSE 1521 5500

