# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 1996-2017 Oracle and/or its affiliates. All rights reserved.
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) Oracle Tuxedo System and Applications Monitor (TSAM) Plus 12cR2 (12.2.2) GA Installer: tsam122200_64_Linux_x86.zip
#     Download from http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html
#
# (2) Oracle TSAM Plus 12.2.2 Rolling Patch 003: p25448043_12220_Linux-x86-64.zip
#     Download from https://updates.oracle.com/Orion/Services/download/p25448043_12220_Linux-x86-64.zip?aru=20968945&patch_file=p25448043_12220_Linux-x86-64.zip
#
# (3) Oracle Database Instant Client: instantclient-basiclite-linux.x64-12.2.0.1.0.zip & instantclient-sqlplus-linux.x64-12.2.0.1.0.zip
#     Download from http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ docker build -t oracle/tsam:12.2.2.1 .

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
    TMPFILES=/tmp/files

# Setup filesystem and oracle user
# Adjust file permissions, go to /u01 as user 'oracle' to proceed with WLS installation
# ------------------------------------------------------------
RUN mkdir -p /u01/oracle && \
    chmod a+xr /u01 && \
    useradd -u 1000 -b /u01 -M -s /bin/bash oracle && \
    chown oracle:oracle -R /u01 && \
    yum install -y libaio vim tar net-tools openssh-server rsync sudo && \
    yum clean all && \
    sshd-keygen > /dev/null 2>&1; \
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config && \
    sed -i '/GSSAPIAuthentication yes/d' /etc/ssh/sshd_config && \
    sed -i "s/^Defaults    requiretty/#Defaults    requiretty/g" /etc/sudoers && \
    echo 'oracle   ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV FMW_PKG=tsam122200_64_Linux_x86.zip \
ORACLT_PKG1=instantclient-basiclite-linux.x64-12.2.0.1.0.zip \
ORACLT_PKG2=instantclient-sqlplus-linux.x64-12.2.0.1.0.zip \
RP_PKG=p25448043_12220_Linux-x86-64.zip

# Copy packages
# -------------
COPY $FMW_PKG \
      $ORACLT_PKG1 \
      $ORACLT_PKG2 \
      $RP_PKG \
      /u01/

# Copy files
# ----------
COPY files/tsam_install.rsp /u01/
COPY files/oraInst.loc /etc/

# Install
# ------------------------------------------------------------
USER oracle
RUN cd /u01 && \
      mkdir oraInventory && \
      cd /u01 && \
      jar xf $FMW_PKG && \
      cd /u01/Disk1/install && \
      chmod -R +x * && \
      sh ./runInstaller.sh -silent -waitforcompletion -responseFile /u01/tsam_install.rsp; \
      if [ $? = 255 ];then \
        sh ./runInstaller.sh -silent -waitforcompletion -responseFile /u01/tsam_install.rsp; \
      fi && \
      rm -rf /u01/Disk1 \
              /u01/tsam_install.rsp \
              /u01/$FMW_PKG

ENV ORACLE_HOME=/u01/oracle/oraHome

# Apply Rolling Patch
# ------------------------------------------------------------
RUN cd /u01/oracle && \
      ln -s $JAVA_HOME oraHome/jdk && \
      mkdir tmp && cd tmp && \
      jar xf /u01/$RP_PKG && \
      /u01/oracle/oraHome/OPatch/opatch apply 25448043.zip && \
      cd && rm -rf tmp /u01/$RP_PKG

WORKDIR /u01/oracle

USER root
COPY files /tmp/files/
RUN mkdir /etc/envs && \
      cp $TMPFILES/bashrc /etc/envs && \
      bash -c "echo . /etc/envs/bashrc >> /etc/bashrc" && \
      bash -c "echo . /etc/envs/bashrc >> /u01/oracle/.bashrc" && \
      cd /u01/oracle && \
      jar xf /u01/$ORACLT_PKG1 && \
      jar xf /u01/$ORACLT_PKG2 && \
      chmod -R +x instantclient_* && \
      mv /u01/oracle/instantclient* /u01/oracle/instantclient && \
      chown -R oracle:oracle \
      $TMPFILES/sbin \
      $TMPFILES/sqlrun \
      $TMPFILES/scripts \
      $TMPFILES/DatabaseUpgradeOracleRP.sh \
      /u01/oracle/instantclient \
      /u01/oracle/.bashrc && \
      mv $TMPFILES/sbin $TMPFILES/scripts /u01/oracle && \
      mv $TMPFILES/sqlrun/* /u01/oracle/instantclient && \
      mv $TMPFILES/DatabaseUpgradeOracleRP.sh /u01/oracle/oraHome/tsam12.2.2.0.0/deploy && \
      rm -rf /u01/$ORACLT_PKG1 \
             /u01/$ORACLT_PKG2

USER oracle

# Define default command to start script.
ENTRYPOINT ["/u01/oracle/sbin/init.sh"]

EXPOSE 7001 22
