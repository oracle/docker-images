# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 1982-2016 Oracle and/or its affiliates. All rights reserved.
#

# Pull base image
# ---------------
FROM oracle/database:12.1.0.2-ee

# Maintainer
# ----------
MAINTAINER Gerald Venzl <gerald.venzl@oracle.com>

# Unix user oracle
USER oracle

# Specify SID and PDB name
ENV ORACLE_SID=TEST \
    ORACLE_PDB=STARTERSET

# Create DB and add startset
RUN $ORACLE_BASE/createDB.sh $ORACLE_SID $ORACLE_PDB && \
    sqlplus / as sysdba @starterset.sql

# Define default command to start Oracle Database. 
CMD $ORACLE_BASE/$RUN_FILE