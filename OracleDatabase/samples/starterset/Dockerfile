# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 1982-2016 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is a sample Dockerfile for adding starter set data
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Run: 
#      $ docker build --build-arg ORACLE_PWD=<Your DB password> -t example/starterset .
#
# Pull base image
# ---------------
FROM oracle/database:12.1.0.2-ee

# Maintainer
# ----------
MAINTAINER Gerald Venzl <gerald.venzl@oracle.com>

ARG ORACLE_PWD

COPY starterset.sql .

# Main script - 4 steps
# 1) Start Listener
# 2) Start Database
# 3) Add starter set data (execute any SQL command in starterset.sql)
# 4) Delete starter set .sql file
RUN bash -lc "lsnrctl start" && \
    echo "startup;" | sqlplus / as sysdba && \
    sqlplus sys/$ORACLE_PWD@//localhost:1521/$ORACLE_PDB as sysdba @starterset.sql && \
    rm starterset.sql

# Expose ports
EXPOSE 1521 5500
    
# Define default command to start Oracle Database. 
CMD $ORACLE_BASE/$RUN_FILE

