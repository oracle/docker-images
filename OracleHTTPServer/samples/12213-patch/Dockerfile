# LICENSE UPL 1.0
#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle HTTP Server install image and applies a patch.

# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) p12345678_122130_Generic.zip
#     Download the patch from http://support.oracle.com
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ sudo docker build -t oracle/ohs:12213-patch .
#

# Pull base image
# ---------------
FROM oracle/ohs:12.2.1.3.0

# Maintainer
# ----------
MAINTAINER Prabhat Kishore <prabhat.kishore@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV PATCH_PKG="p12345678_122130_Linux-x86-64.zip"

# Copy supplemental package and scripts
# --------------------------------
COPY $PATCH_PKG /u01/

# Installation of Supplemental Quick Installer
# --------------------------------------------
USER oracle
RUN  cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG  && cd - && \
     cd /u01/12345678 && $ORACLE_HOME/OPatch/opatch apply -silent && \
     rm /u01/$PATCH_PKG

WORKDIR ${ORACLE_HOME}


CMD ["/u01/oracle/container-scripts/provisionOHS.sh"]
