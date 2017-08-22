#
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle FMW Infrastructure image and applies a PSU patch.

# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) p25871788_122120_Generic.zip
#     Download the PSU patch from http://support.oracle.com
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ sudo docker build -t fmw-infrastructure-12212-psu25871788 .
#

# Pull base image
# ---------------
FROM oracle/fmw-infrastructure:12.2.1.2

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV PSU_PKG="p25871788_122120_Generic.zip"

# Copy supplemental package and scripts
# --------------------------------
USER root
COPY $PSU_PKG /u01/
RUN chmod 777 /u01/$PSU_PKG 

# Installation of Supplemental Quick Installer 
# --------------------------------------------
USER oracle
RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PSU_PKG && cd - && \
    cd /u01/25871788 && $ORACLE_HOME/OPatch/opatch apply -silent && \
    rm /u01/$PSU_PKG 

WORKDIR ${ORACLE_HOME}

CMD ["/u01/oracle/container-scripts/createOrStartInfraDomain.sh"]
