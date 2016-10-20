# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic image by installing the Supplemental package of WebLogic which 
# includes extra samples of Java EE, Coherence applications, and Multitenant domains. 
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) p24286152_122110_Generic.zip
#     Download the PSU patch from http://support.oracle.com
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ sudo docker build -t 12211-psu24286152 .
#

# Pull base image
# ---------------
FROM oracle/weblogic:12.2.1.1-developer

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV PSU_PKG="p24286152_122110_Generic.zip" 

# Copy supplemental package and scripts
# --------------------------------
COPY $PSU_PKG /u01/

# Installation of Supplemental Quick Installer 
# --------------------------------------------
RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PSU_PKG && cd - && \
    chown oracle:oracle -R /u01 && \ 
    echo oracle:oracle | chpasswd && \ 
    su -c "cd /u01/24286152 && $ORACLE_HOME/OPatch/opatch apply -silent" - oracle && \
    rm /u01/$PSU_PKG 

WORKDIR ${ORACLE_HOME}


CMD ["/u01/oracle/createAndStartEmptyDomain.sh"]
