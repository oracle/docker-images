# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle FMW Infrastructure 12.2.1.2
# 
# HOW TO BUILD THIS IMAGE
# -----------------------
# The Oracle FMW Infrastructure image extends the Oracle WebLogic Infrastructure 12.2.1.2 image, you must first build the Oracle WebLogic Infrastructure image.
# Run: 
#      $ docker build -f Dockerfile -t oracle/fmw-infrastructure:12.2.1.2
#
# IMPORTANT
# ---------
# The resulting image of this Dockerfile contains a FMW Infra Base Domain.
#
# From 
# -------------------------
FROM oracle/weblogic:12.2.1.2-infrastructure

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>


# Common environment variables required for this build 
# ----------------------------------------------------
ENV ORACLE_HOME=/u01/oracle \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
    DOMAIN_NAME="${DOMAIN_NAME:-InfraDomain}" \
    DOMAIN_HOME=/u01/oracle/user_projects/domains/${DOMAIN_NAME:-InfraDomain} \
    PATH=$PATH:/usr/java/default/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts


USER root    
# Setup subdirectory container-scripts
# ------------------------------------------------------------  
RUN mkdir -p /u01/oracle/container-scripts


# Copy packages and scripts
# -------------
COPY container-scripts/* /u01/oracle/container-scripts/

RUN chmod +x /u01/oracle/container-scripts/*.sh && \
    yum install -y libaio && \
    yum clean all

USER oracle
WORKDIR ${ORACLE_HOME}

# Define default command to start script.
CMD ["/u01/oracle/container-scripts/createInfraDomainAndStartAdmin.sh"]
