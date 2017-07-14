#!/bin/bash
#
# Since: June, 2017
# Author: hadi.koesnodihardjo@oracle.com
# Description: script to build a Docker image for Oracle GoldenGate for Oracle.
#
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
#
FROM oraclelinux:7-slim
MAINTAINER OGG PM <bobby.curtis@oracle.com>
#Container Additional Environment Variables
ENV OGG_SHIPHOME=V100692-01.zip \
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
    ODB_SHIPHOME1=database1.zip \
    ODB_SHIPHOME2=database2.zip \
    STAGE_SOFTWARE=/u01/software \
    ORACLE_HOSTNAME=db12cgg \
    HOSTNAME=db12cgg
ENV PATH=$PATH:$ORACLE_HOME/bin:$OGG_HOME \
    LD_LIBRARY_PATH=.:./lib:/usr/lib/jvm/jre/lib/amd64/server:$OGG_HOME:$LD_LIBRAY_PATH:$ORACLE_HOME/lib \
    CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib:$CLASSPATH
#Command during the build
RUN yum install -y java-1.8.0-openjdk vim-minimal util-linux.x86_64 zip unzip tar oracle-rdbms-server-12cR1-preinstall && \ 
    yum clean all

#DB SHIPHOME
RUN groupadd oracle && \ 
    usermod -aG oracle oracle
RUN mkdir -p $ORACLE_HOME $STAGE_SOFTWARE
ADD $ODB_SHIPHOME1 $STAGE_SOFTWARE 
ADD $ODB_SHIPHOME2 $STAGE_SOFTWARE
ADD db_install.rsp $STAGE_SOFTWARE
ADD runSQL.sql $STAGE_SOFTWARE
EXPOSE $ORACLE_DB_LIST_PORT
EXPOSE $EM_EXPRESS_PORT

#OGG SHIPHOME
RUN mkdir -p $OGG_HOME && rmdir $OGG_HOME
RUN chmod -R 777 /u01
ADD $OGG_SHIPHOME $STAGE_SOFTWARE 
EXPOSE $OGG_PORT

#entrypoint info
ADD entrypoint.sh /
ENTRYPOINT /entrypoint.sh
