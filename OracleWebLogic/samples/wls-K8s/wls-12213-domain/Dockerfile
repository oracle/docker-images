#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic image by creating a sample domain.
#
# Util scripts are copied into the image enabling users to plug NodeManager
# automatically into the AdminServer running on another container.
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
# docker build --build-arg ADMIN_PASSWORD=<Admin Password> --build-arg ADMIN_USER=<Admin Username> -t wls-12213-domain .
#      $ sudo docker build -t 12213-domain
#
# Pull base image
# ---------------
FROM oracle/weblogic:12.2.1.3-developer

# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# Build time arguments
# --------------------
ARG number_of_ms=5
ARG ADMIN_PASS
ARG ADMIN_USER


# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV MW_HOME="$ORACLE_HOME" \
    PATH="$ORACLE_HOME/wlserver/server/bin:$ORACLE_HOME/wlserver/../oracle_common/modules/org.apache.ant_1.9.2/bin:$JAVA_HOME/jre/bin:$JAVA_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$ORACLE_HOME/oracle_common/common/bin:$ORACLE_HOME/wlserver/common/bin:$ORACLE_HOME/user_projects/domains/medrec/bin:$ORACLE_HOME/wlserver/samples/server/medrec/:$ORACLE_HOME/wlserver/samples/server/:$ORACLE_HOME/wlserver/../oracle_common/modules/org.apache.maven_3.2.5/bin" \
    DEFAULT_AS_NAME="AdminServer" \
    NUMBER_OF_MS="${number_of_ms}" \
    DOMAINS_DIR=$ORACLE_HOME/wlserver/samples/domains \
    DOMAIN_NAME=oow-demo-domain \
    DEFAULT_MS_NAME=ms-0 \
    MSNAME_PREFIX=ms- \
    DNS_DOMAIN_NAME=wls-subdomain \
    WLST="$ORACLE_HOME/oracle_common/common/bin/wlst.sh"

# Copy scripts
# --------------------------------
USER root
COPY container-scripts/* /u01/oracle/
RUN chown oracle:oracle /u01/oracle/*.sh
RUN chown oracle:oracle /u01/oracle/*.py
USER oracle
RUN chmod +x /u01/oracle/*.sh /u01/oracle/*.py

# Default directory creation, Admin Server boot
# ---------------------------------------------
RUN . $ORACLE_HOME/wlserver/server/bin/setWLSEnv.sh && \
    cd /u01/oracle && \
    ./provision-domain.sh $DOMAIN_NAME $ORACLE_HOME/wlserver/common/templates/wls/wls.jar $DOMAINS_DIR $ADMIN_USER $ADMIN_PASS 8001 $DEFAULT_MS_NAME 8011 dev $NUMBER_OF_MS "DockerCluster" $DNS_DOMAIN_NAME

EXPOSE 8011 8001
WORKDIR $DOMAINS_DIR/$DOMAIN_NAME
