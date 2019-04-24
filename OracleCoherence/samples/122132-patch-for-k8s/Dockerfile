# LICENSE UPL 1.0
#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle Coherence install image and applies a patch.

# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) p29204496_122130_Generic.zip
#     Download the patch from http://support.oracle.com
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ sudo docker build -t oracle/coherence:12.2.1.3.2 .
#

# Pull base image
# ---------------
FROM oracle/coherence:12.2.1.3

# Maintainer
# ----------
MAINTAINER Patrick Fry <patrick.fry@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV PATCH_PKG="p29204496_122130_Generic.zip"

# Copy supplemental package and scripts
# --------------------------------
COPY $PATCH_PKG /u01/

# Installation of Supplemental Quick Installer
# --------------------------------------------
USER oracle
RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG && cd - && \
    cd /u01/122132 && $ORACLE_HOME/OPatch/opatch apply -silent && cd - && \
    rm -rf /u01/122132 && rm /u01/$PATCH_PKG

WORKDIR ${ORACLE_HOME}
