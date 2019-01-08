#
# Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic image in DockerStore
# configures a Data Source using WLST online to connect to an Oracle DB
# container from DockerStore
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ sudo docker build -t 12212-oradb-wlsstore .
#

# Pull base image
# ---------------
FROM store/oracle/weblogic:12.2.1.2

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV MW_HOME="$ORACLE_HOME" \
    DOMAIN_HOME=/u01/oracle/user_projects/domains/base_domain \
    PATH=$PATH:/u01/oracle:$DOMAIN_HOME

# Environment variables required for application deployment
# -------------------------------------------------------------
ENV APP_NAME="auction" \
    APP_PKG_FILE="auction.war" \
    APP_PKG_LOCATION="/u01/oracle"


# Copy supplemental package and scripts
# --------------------------------
USER root
COPY container-scripts/*  /u01/oracle/
RUN chmod +xr /u01/oracle/*.sh

# Installation of Supplemental Quick Installer
# --------------------------------------------
USER oracle
RUN cd /u01/oracle && \
    ./ds-wlst-online-config.sh  && \
    wlst /u01/oracle/app-deploy.py


EXPOSE $ADMIN_PORT
WORKDIR $DOMAIN_HOME

CMD ["startWebLogic.sh"]
