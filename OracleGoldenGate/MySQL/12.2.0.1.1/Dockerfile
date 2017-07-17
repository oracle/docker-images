# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE GoldenGate DOCKERFILES PROJECT
# -----------------------------------------
# This is the DockerFile for Oracle GoldenGate for MySQL database 12.2.0.1.1
#
# IMPORTANT
# -------------------------------------------
# The resulting image of this Dockerfile would have Oracle MySQL 5.7.18 and GoldenGate for MySQL 12.2.0.1.1 installed in standalone mode.
# Any MySQL 5.7.8 and up image would work, replace and rebuild as needed.
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) ggs_Linux_x64_MySQL_64bit.zip (Oracle GoldenGate 12c for MySQL(12.2.0.1.1))
#     Download from http://www.oracle.com/technetwork/middleware/goldengate/downloads/index.html
#
# This image uses MySQL 5.7.18 as an example.
FROM mysql/mysql-server:5.7.18
MAINTAINER Bobby Curtis <bobby.curtis@oracle.com>
#Container Additional Environment Variables
ENV OGG_SHIPHOME=ggs_Linux_x64_MySQL_64bit.zip \
    OGG_HOME=/u01/app/oracle/product/12.2.0.1.1/oggmysql_1 \
    OGG_PORT=1700 \
    STAGE_SOFTWARE=/u01/software \
    MYSQL_UNIX_PORT=/var/lib/mysql/mysql.sock \
    MYSQL_HOME=/var/lib/mysql
ENV PATH=$OGG_HOME:$PATH \
    LD_LIBRARY_PATH=/usr/lib/jvm/jre/lib/amd64/server:$OGG_HOME:$OGG_HOME/lib:$LD_LIBRARY_PATH
#Command during the build
RUN yum install -y java-1.8.0-openjdk util-linux zip unzip tar && yum clean all && \
    mkdir -p $OGG_HOME $STAGE_SOFTWARE
ADD ogg_*.txt  $STAGE_SOFTWARE/
RUN sed -i "118r $STAGE_SOFTWARE/ogg_inst.txt" /entrypoint.sh && \
    sed -i "3r $STAGE_SOFTWARE/ogg_func.txt" /entrypoint.sh && \
    sed -i -e "$ r $STAGE_SOFTWARE/ogg_cnf.txt" /etc/my.cnf
#OGG SHIPHOME
ADD $OGG_SHIPHOME $STAGE_SOFTWARE
EXPOSE $OGG_PORT
