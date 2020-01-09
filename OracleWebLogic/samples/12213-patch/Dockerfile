# LICENSE UPL 1.0
#
# Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic install image and applies a patch.

# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) p27117282_122130_Generic.zip
#     Download the patch from http://support.oracle.com
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ sudo docker build -t oracle/weblogic:12213-p27117282 .
#

# Pull base image
# ---------------
FROM oracle/weblogic:12.2.1.3-developer

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV PATCH_PKG="p27117282_122130_Generic.zip"

# Copy supplemental package and scripts
# --------------------------------
COPY --chown=oracle:oracle $PATCH_PKG /u01/

# Installation of Supplemental Quick Installer
# --------------------------------------------
USER oracle
RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG && cd - && \
    cd /u01/27117282 && $ORACLE_HOME/OPatch/opatch apply -silent && \
    rm /u01/$PATCH_PKG

WORKDIR ${ORACLE_HOME}


CMD ["/u01/oracle/createAndStartEmptyDomain.sh"]
