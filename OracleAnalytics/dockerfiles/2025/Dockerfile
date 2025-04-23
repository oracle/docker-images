# Copyright (c) 2025 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Analytics Server 2025 (8.2)
# 
# REQUIRED FILE(S) TO BUILD THIS IMAGE
# ----------------------------------
# (1) Oracle_Analytics_Server_Linux_2025(8.2).zip
#     Download the installer file from https://www-sites.oracle.com/solutions/business-analytics/analytics-server/analytics-server.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build -t oracle/analyticsserver:2025 .
#
# Pull base image
# ---------------
FROM oracle/fmw-infrastructure:12.2.1.4

# Labels
# ------
LABEL "maintainer"="Padam Bengani <padam.bengani@oracle.com>"

#Common ENV
#-----------
ENV ORACLE_HOME=/u01/oracle

# Environment variables required for this build (do NOT change)
# (DOMAIN_NAME/HOME are reset here, to avoid FMW Infra environment leaking through)
# -------------------------------------------------------------
ENV BI_DISTRO_ZIP1=Oracle_Analytics_Server_Linux_2025(8.2).zip \
    BI_INSTALLER1=Oracle_Analytics_Server_2025_Linux.jar \
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
RUN dnf -y install unzip hostname libnsl && dnf clean all

USER oracle
RUN unzip "/u01/$BI_DISTRO_ZIP1" -d /u01 && \
    "$JAVA_HOME/bin/java" -jar "/u01/$BI_INSTALLER1" -silent -responseFile /u01/install.file \
    -invPtrLoc /u01/oraInst.loc -ignoreSysPrereqs -force -novalidation ORACLE_HOME="$ORACLE_HOME" \
    INSTALL_TYPE="Oracle Analytics" && \
    rm "/u01/$BI_DISTRO_ZIP1" "/u01/$BI_INSTALLER1" /u01/oraInst.loc /u01/install.file

WORKDIR $ORACLE_HOME

# Prepare for Config
#-------------------------------------------------------------
EXPOSE 9500-9999
COPY createAndStartDomain.sh wait_for_db.sh /u01/

CMD ["/u01/createAndStartDomain.sh"]
