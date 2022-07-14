# LICENSE UPL 1.0
#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle FMW Infrastructure install image and applies a patch.

# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) p27117282_122130_Generic.zip
#     Download the patch from http://support.oracle.com
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ docker build -t oracle/fmw-infra:12213-p27117282 .
#

# Pull base image
# ---------------
FROM oracle/fmw-infrastructure:12.2.1.4

# Maintainer
# ----------
MAINTAINER Padam Bengani <padam.bengani@oracle.com>

#Common ENV
#-----------
ENV OPATCH_NO_FUSER=true

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV PATCH_PKG_1="p28186730_139428_Generic.zip" \
    PATCH_PKG_2="p33903365_122140_Generic.zip"

# Copy supplemental package and scripts
# --------------------------------
COPY --chown=oracle:oracle $PATCH_PKG_1 /u01/
COPY --chown=oracle:oracle $PATCH_PKG_2 /u01/

# Installation of Supplemental Quick Installer
# --------------------------------------------
USER oracle
RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG_1 && cd - && \
    cd /u01/6880880 && $JAVA_HOME/bin/java -jar /u01/6880880/opatch_generic.jar -silent oracle_home=$ORACLE_HOME && \
    rm /u01/$PATCH_PKG_1

RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG_2 && cd - && \
    cd /u01/33903365 && $ORACLE_HOME/OPatch/opatch apply -silent && \
    rm /u01/$PATCH_PKG_2

WORKDIR ${ORACLE_HOME}


CMD ["/u01/oracle/container-scripts/createOrStartInfraDomain.sh"]
