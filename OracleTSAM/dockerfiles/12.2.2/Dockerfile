# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 1996-2017 Oracle and/or its affiliates. All rights reserved.
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) Oracle Tuxedo System and Applications Monitor (TSAM) Plus 12cR2 (12.2.2) GA Installer: tsam122200_64_Linux_x86.zip
#     Download from http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html
#
# (2) Oracle Database Instant Client: oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm & oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm
#     Download from http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ docker build -t oracle/tsam:12.2.2 .

# Pull base image
# ---------------
FROM oracle/serverjre:8

# Maintainer
# ----------
MAINTAINER Chris Guo <chris.guo@oracle.com>

# Common environment variables required for this build (do NOT change)
# --------------------------------------------------------------------
ENV ORACLE_HOME=/u01/oracle \
    PATH=$PATH:/usr/java/default/bin \
    TMPFILES=/tmp/files \
    FMW_PKG=tsam122200_64_Linux_x86.zip \
    ORACLT_PKG1=oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm \
    ORACLT_PKG2=oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm

# Copy packages
# -------------
COPY $FMW_PKG \
      $ORACLT_PKG1 \
      $ORACLT_PKG2 \
      /u01/

# Setup filesystem and oracle user, install required packages including Oracle Instant Client
# ------------------------------------------------------------
RUN mkdir -p /u01/oracle && \
    if [ "`/bin/ls -l /u01/$FMW_PKG|cut -c8`" != r ];then \
      chmod a+r /u01/$FMW_PKG; \
    fi && \
    useradd -u 1000 -b /u01 -M -s /bin/bash oracle && \
    chown oracle:oracle /u01 /u01/oracle && \
    yum install -y vim tar net-tools && \
    yum localinstall -y /u01/$ORACLT_PKG1 /u01/$ORACLT_PKG2 && \
    rm -f /u01/$ORACLT_PKG1 /u01/$ORACLT_PKG2 && \
    yum clean all

# Copy files
# ----------
COPY files/tsam_install.rsp /u01/
COPY files/oraInst.loc /etc/

# Install
# ------------------------------------------------------------
USER oracle
RUN cd /u01 && \
      mkdir oraInventory && \
      jar xf $FMW_PKG && \
      cd /u01/Disk1/install && \
      chmod -R +x * && \
      sh ./runInstaller.sh -silent -waitforcompletion -responseFile /u01/tsam_install.rsp && \
      rm -rf /u01/Disk1 \
              /u01/Translations \
              /u01/tsam_install.rsp \
              /u01/$FMW_PKG

ENV ORACLE_HOME=/u01/oracle/oraHome
WORKDIR /u01/oracle

USER root
COPY files /tmp/files/
RUN  cd /u01/oracle && \
      mkdir /u01/oracle/instantclient && \
      cp -rf $TMPFILES/sbin $TMPFILES/scripts /u01/oracle && \
      rm -rf $TMPFILES/sbin $TMPFILES/scripts && \
      cp -f $TMPFILES/sqlrun/* /u01/oracle/instantclient && \
      rm -rf $TMPFILES/sqlrun && \
      chown -R oracle:oracle \
        /u01/oracle/sbin \
        /u01/oracle/instantclient \
        /u01/oracle/scripts && \
        sed -i "s?TSAMDeployer.jar:?TSAMDeployer.jar:/usr/lib/oracle/12.2/client64/lib/ojdbc8.jar:?" \
        /u01/oracle/oraHome/tsam12.2.2.0.0/deploy/DatabaseDeployer.sh

USER oracle

# Define default command to start script.
ENTRYPOINT ["/bin/bash", "/u01/oracle/sbin/init.sh"]

EXPOSE 7001 7002
