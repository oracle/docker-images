# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 1982-2016 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is a sample Dockerfile for creating your own database
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Run: 
#      $ docker build \
#        --build-arg DB_PWD=<Original DB SYS password> \
#        --build-arg DB_PWD_NEW=<New DB password> \
#        --build-arg SID=<Database SID> \
#        --build-arg PDB=<PDB name> \
#        -t example/customdb .
#
# Pull base image
# ---------------
FROM oracle/database:12.1.0.2-ee

# Maintainer
# ----------
MAINTAINER Gerald Venzl <gerald.venzl@oracle.com>

USER oracle

# Oracle password, new SID and PDB name (do NOT change)
# -----------------------------------------------------
ARG DB_PWD
ARG DB_PWD_NEW=$DB_PWD
ARG SID
ARG PDB
  
COPY $CONFIG_RSP .

# Delete preconfigured database
# -----------------------------
RUN echo "startup;" | sqlplus / as sysdba && \
    dbca -silent -deleteDatabase -sourceDB $ORACLE_SID -sysDBAUserName sys -sysDBAPassword $DB_PWD && \
    rm -rf $ORACLE_BASE/diag/rdbms/* && \
    rm -rf $ORACLE_BASE/oradata/$ORACLE_SID

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV ORACLE_SID_ORG=$ORACLE_SID \
    ORACLE_PDB_ORG=$ORACLE_PDB \
    ORACLE_SID=$SID            \
    ORACLE_PDB=$PDB

# Replace place holders
# ---------------------
RUN sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" $CONFIG_RSP                               &&  \
    sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" $CONFIG_RSP                               &&  \
    sed -i -e "s|###ORACLE_PWD###|$DB_PWD_NEW|g" $CONFIG_RSP                               &&  \
    sed -i -e "s|$ORACLE_SID_ORG|$ORACLE_SID|g"  $ORACLE_HOME/network/admin/listener.ora   &&  \
    sed -i -e "s|$ORACLE_SID_ORG|$ORACLE_SID|g"  $ORACLE_HOME/network/admin/tnsnames.ora   &&  \
    sed -i -e "s|$ORACLE_PDB_ORG|$ORACLE_PDB|g"  $ORACLE_HOME/network/admin/tnsnames.ora   &&  \
    sed -i -e "s|$ORACLE_SID_ORG|$ORACLE_SID|g"  $HOME/.bashrc                             &&  \
    sed -i -e "s|$ORACLE_PDB_ORG|$ORACLE_PDB|g"  $HOME/.bashrc                             &&  \
    source $HOME/.bashrc

# Start LISTENER and run DBCA
# ---------------------------
RUN bash -lc "lsnrctl start" && \
    dbca -silent -responseFile $CONFIG_RSP && \
    echo "ALTER PLUGGABLE DATABASE $ORACLE_PDB SAVE STATE;" | sqlplus / as sysdba && \
    rm -rf $CONFIG_RSP

EXPOSE 1521 5500
    
# Define default command to start Oracle Database.
# ------------------------------------------------
CMD $ORACLE_BASE/$RUN_FILE
