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
# Run:
#      $ sudo docker build -t 12212-msiserver .
#

# Pull base image
# ---------------
FROM oracle/weblogic:12.2.1.2-developer

# Maintainer
# ----------
MAINTAINER Aseem Bajaj <aseem.bajaj@oracle.com>

# Arguments
# ---------
ARG number_of_ms=10
ARG domains_dir=wlserver/samples/domains
ARG domain_name=msi-sample
ARG ms_name_prefix=ms
ARG ms_port=8011
ARG prod_or_dev=dev

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV MW_HOME="$ORACLE_HOME" \
    PATH="$ORACLE_HOME/wlserver/server/bin:$ORACLE_HOME/wlserver/../oracle_common/modules/org.apache.ant_1.9.2/bin:$JAVA_HOME/jre/bin:$JAVA_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$ORACLE_HOME/oracle_common/common/bin:$ORACLE_HOME/wlserver/common/bin:$ORACLE_HOME/user_projects/domains/medrec/bin:$ORACLE_HOME/wlserver/samples/server/medrec/:$ORACLE_HOME/wlserver/samples/server/:$ORACLE_HOME/wlserver/../oracle_common/modules/org.apache.maven_3.2.5/bin" \
    NUMBER_OF_MS=$number_of_ms \
    DOMAINS_DIR=$ORACLE_HOME/$domains_dir \
    DOMAIN_NAME=$domain_name \
    MS_NAME_PREFIX=$ms_name_prefix \
    DEFAULT_MS_NAME=${ms_name_prefix}1 \
    MS_PORT=$ms_port \
    PROD_OR_DEV=$prod_or_dev

# Copy scripts
# --------------------------------
USER oracle
COPY container-scripts/* /u01/oracle/

# Default directory creation, Admin Server boot
# ---------------------------------------------
RUN . $ORACLE_HOME/wlserver/server/bin/setWLSEnv.sh && \
    cd /u01/oracle && \
    ./provision-domain-for-msi.sh $DOMAIN_NAME $ORACLE_HOME/wlserver/common/templates/wls/wls.jar $DOMAINS_DIR weblogic weblogic1 8001 $DEFAULT_MS_NAME $MS_PORT $PROD_OR_DEV $NUMBER_OF_MS $MS_NAME_PREFIX

EXPOSE $MS_PORT
WORKDIR $DOMAINS_DIR/$DOMAIN_NAME
ENTRYPOINT ["/u01/oracle/launcher.sh"]
