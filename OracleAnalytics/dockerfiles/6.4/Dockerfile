# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Analytics Server 2022 (6.4)
# 
# REQUIRED FILE(S) TO BUILD THIS IMAGE
# ----------------------------------
# (1) Oracle_Analytics_Server_Linux_2022(6.4).zip
#     Download the installer file from https://www-sites.oracle.com/solutions/business-analytics/analytics-server/analytics-server.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build -t oracle/biplatform:6.4 .
#
# Pull base image
# ---------------
FROM oracle/fmw-infrastructure:12.2.1.4

# Maintainer
# ----------
MAINTAINER Padam Bengani <padam.bengani@oracle.com>

#Common ENV
#-----------
ENV ORACLE_HOME=/u01/oracle

# Environment variables required for this build (do NOT change)
# (DOMAIN_NAME/HOME are reset here, to avoid FMW Infra environment leaking through)
# -------------------------------------------------------------
ENV BI_DISTRO_ZIP1=Oracle_Analytics_Server_Linux_2022(6.4).zip \
    BI_INSTALLER1=Oracle_Analytics_Server_Linux_6.4.0.jar \
    DOMAIN_NAME="${BI_DOMAIN_NAME:-bi}" \
    DOMAINS_DIR=$ORACLE_HOME/user_projects/domains \
    DOMAIN_HOME=$ORACLE_HOME/user_projects/domains/${BI_DOMAIN_NAME:-bi}

# Copy packages
# -------------
COPY $BI_DISTRO_ZIP1 install.file oraInst.loc /u01/

# Install
#-------------------------------------------------------------
USER root

# tools for installing and running BI
RUN yum -y install unzip hostname && rm -rf /var/cache/yum

USER oracle
RUN cd /u01 && unzip $BI_DISTRO_ZIP1 && cd - && \
    $JAVA_HOME/bin/java -jar /u01/$BI_INSTALLER1 -silent -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="Oracle Analytics" && \
    rm /u01/$BI_DISTRO_ZIP1 /u01/$BI_INSTALLER1 /u01/oraInst.loc /u01/install.file

USER oracle
WORKDIR $ORACLE_HOME 

# Prepare for Config
#-------------------------------------------------------------
EXPOSE 9500-9999
COPY createAndStartDomain.sh wait_for_db.sh /u01/

CMD ["/u01/createAndStartDomain.sh"]
