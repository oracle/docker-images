# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE GoldenGate DOCKERFILES PROJECT
# -----------------------------------------
# This is the DockerFile for Oracle GoldenGate for Oracle database 12.2.0.1.1
#
# IMPORTANT
# -------------------------------------------
# The resulting image of this Dockerfile would have Oracle 12.1.0.2 and GoldenGate for Oracle Database 12.2.0.1.1 installed in standalone mode.
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) fbo_ggs_Linux_x64_shiphome.zip (Oracle GoldenGate 12c for Oracle Database (12.2.0.1.1))
#     Download from http://www.oracle.com/technetwork/middleware/goldengate/downloads/index.html
#
# 
FROM oracle/database:12.1.0.2-ee
MAINTAINER Bobby Curtis <bobby.curtis@oracle.com>
#Container Additional Environment Variables
ENV OGG_SHIPHOME=fbo_ggs_Linux_x64_shiphome.zip \
    OGG_HOME=/u01/app/oracle/product/12.2.0.1/oggcore_1 \
    OGG_PORT=9500 \
    ORACLE_HOME=/u01/app/oracle/product/12.1.0.2/dbhome_1 \
    ORACLE_BASE=/u01/app/oracle \
    ORACLE_SID=db12c \
    ORACLE_INVENTORY=/u01/app/oraInventory \
    ORACLE_DB_LIST_PORT=1521 \
    DB_CHARSET=WE8ISO8859P9 \
    SYS_PASSWORD=Welcome1 \
    TNS_ADMIN_FILE=$ORACLE_HOME/network/admin/tnsnames.ora \
    GLOBAL_DB_NAME=${HOSTNAME} \
    EM_EXPRESS_PORT=5500 \
    STAGE_SOFTWARE=/u01/software 
ENV PATH=$PATH:$ORACLE_HOME/bin:$OGG_HOME \
    LD_LIBRARY_PATH=/usr/lib/jvm/jre/lib/amd64/server:$OGG_HOME:$OGG_HOME/lib:$LD_LIBRAY_PATH:$ORACLE_HOME/lib \
    CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib:$CLASSPATH
#Command during the build
USER root
RUN yum install -y java-1.8.0-openjdk util-linux zip unzip tar && yum clean all && \
    mkdir -p $ORACLE_HOME $STAGE_SOFTWARE
#Overwrite the original $RUN_FILE
ADD runOracleGG.sh $ORACLE_BASE/$RUN_FILE
#OGG SHIPHOME
ADD $OGG_SHIPHOME runSQL.sql $STAGE_SOFTWARE/ 
EXPOSE $OGG_PORT
