#!/bin/bash
#
# Since: June, 2017
# Author: hadi.koesnodihardjo@oracle.com
# Description: script to build a Docker image for Oracle GoldenGate for non-Oracle (MySQL).
#
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
#
FROM mysql/mysql-server:5.7.18
MAINTAINER OGG QA <hadi.koesnodihardjo@oracle.com>
#Container Additional Environment Variables
ENV OGG_SHIPHOME=V100691-01.zip \
    OGG_HOME=/u01/app/oracle/product/12.2.0.1.1/oggmysql_1 \
    OGG_PORT=1700 \
    STAGE_SOFTWARE=/u01/software \
    MYSQL_ROOT_PASSWORD=pakalolo \
    MYSQL_UNIX_PORT=/var/lib/mysql/mysql.sock \
    MYSQL_HOME=/var/lib/mysql
ENV PATH=.:$PATH:$OGG_HOME \
    LD_LIBRARY_PATH=.:./lib:/usr/lib/jvm/jre/lib/amd64/server:$OGG_HOME:$LD_LIBRAY_PATH
#Command during the build
RUN yum install -y java-1.8.0-openjdk vim-minimal util-linux.x86_64 zip unzip tar && yum clean all
#images pre 5.7.6,5.7.7 doesn't has the follwoing to init db
RUN mkdir -p $OGG_HOME $STAGE_SOFTWARE
ADD ogg_func.txt $STAGE_SOFTWARE
ADD ogg_inst.txt $STAGE_SOFTWARE
ADD ogg_cnf.txt  $STAGE_SOFTWARE
RUN sed -i "3r $STAGE_SOFTWARE/ogg_func.txt" /entrypoint.sh
RUN sed -i -e "s/^exec /#exec /" /entrypoint.sh
RUN sed -i "/^#exec /r $STAGE_SOFTWARE/ogg_inst.txt" /entrypoint.sh
RUN sed -i -e "$ r $STAGE_SOFTWARE/ogg_cnf.txt" /etc/my.cnf
#OGG SHIPHOME
ADD $OGG_SHIPHOME $STAGE_SOFTWARE
EXPOSE $OGG_PORT
