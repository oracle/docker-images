# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Business Intelligence 12.2.1.2.0
# 
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) fmw_12.2.1.2.0_bi_linux64_Disk1_1of2.zip 
# (2) fmw_12.2.1.2.0_bi_linux64_Disk1_2of2.zip
#     Download the two installer files from http://www.oracle.com/technetwork/middleware/bi/downloads/default-3237328.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build -t oracle/biplatform:12.2.1.2.0 . 
#
# Pull base image
# ---------------
FROM oracle/weblogic:12.2.1.2-infrastructure

# Maintainer
# ----------
MAINTAINER Steve Phillips <steve.phillips@oracle.com>

#Common ENV
#-----------
ENV ORACLE_HOME=/u01/oracle

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV BI_DISTRO_ZIP1=fmw_12.2.1.2.0_bi_linux64_Disk1_1of2.zip \
    BI_DISTRO_ZIP2=fmw_12.2.1.2.0_bi_linux64_Disk1_2of2.zip \
    BI_INSTALLER1=bi_platform-12.2.1.2.0_linux64.bin \
    BI_INSTALLER2=bi_platform-12.2.1.2.0_linux64-2.zip

# Copy packages
# -------------
COPY $BI_DISTRO_ZIP1 $BI_DISTRO_ZIP2 install.file oraInst.loc /u01/

# Install
#-------------------------------------------------------------
USER root

# tools for installing BI
RUN yum -y install unzip 
# tools required for running BI
RUN yum -y install libaio hostname

USER oracle
RUN cd /u01 && unzip $BI_DISTRO_ZIP1 && unzip $BI_DISTRO_ZIP2 && cd - && \
    /u01/$BI_INSTALLER1 -silent -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="BI Platform Distribution with Samples" && \
    rm /u01/$BI_DISTRO_ZIP1 /u01/$BI_DISTRO_ZIP2 /u01/$BI_INSTALLER1 /u01/$BI_INSTALLER2 /u01/oraInst.loc /u01/install.file

USER oracle
WORKDIR $ORACLE_HOME 

# Prepare for Config
#-------------------------------------------------------------
EXPOSE 9500-9999
COPY createAndStartDomain.sh wait_for_db.sh /u01/

CMD ["/u01/createAndStartDomain.sh"]
