# LICENSE UPL 1.0
#
# Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic image by creating an domain on which
# a managed server can be launched in Managed Server Independence (MSI) mode
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ sudo docker build -t 12212-domain-resources-online -f Dockerfile .
#

# Pull base image
# ---------------
FROM 12212-domain

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV PATH=$PATH:/u01/oracle

# Copy scripts
# --------------------------------
USER root
COPY container-scripts/* /u01/oracle/

RUN chmod +xr /u01/oracle/jms-wlst-online-config.sh && \
    chown oracle:oracle -R /u01/oracle


# Default directory creation, Admin Server boot
# ---------------------------------------------
USER oracle
RUN . $ORACLE_HOME/wlserver/server/bin/setWLSEnv.sh && \
    cd /u01/oracle && \
    ./jms-wlst-online-config.sh
