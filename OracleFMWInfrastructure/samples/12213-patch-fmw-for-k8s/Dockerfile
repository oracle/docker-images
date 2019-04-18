# LICENSE UPL 1.0
#
# Copyright (c) 2018, 2019 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle FMW Infrastructure image, and applies necesary 
# patch for the WebLogic Kubernetes Operator 2.2.  The patch 29135930 is applied on top 
# of FMW Infastructure 12.2.1.3.

# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
#  p29135930_122130_Generic.zip (On top of WebLogic Server 12.2.1.3)
#  Download the patches from http://support.oracle.com
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ sudo docker build -t oracle/fmw-infrastructure:12213-update-k8s .
#

# Build base image
# -----------------
# This patched image extends the FMW Infrastructure 12.2.1.3 image.  Before patching make sure you have built the FMW Infrastructure 12.2.1.3 image.
#   cd docker-images/OracleFMWInfrastructure/dockerfiles
#   ./buildDockerImage.sh -v 12.2.1.3 -g
#
# Extend the FMW Infrastructure 12.2.1.3 image
# --------------------------------------------
FROM oracle/fmw-infrastructure:12.2.1.3

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# Environment variables required for this build.
# -------------------------------------------------------------
ENV PATCH_PKG="p29135930_122130_Generic.zip"

# Copy patch 29135930 
# --------------------------------
COPY $PATCH_PKG /u01/

# Apply Patch 29135930
# --------------------------------------------
USER oracle
RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG && \
    cd /u01/29135930 && $ORACLE_HOME/OPatch/opatch apply -silent && \
    $ORACLE_HOME/OPatch/opatch util cleanup -silent && \
    rm /u01/$PATCH_PKG && \
    rm -rf /u01/29135930 && \
    rm -rf /u01/oracle/cfgtoollogs/opatch/* 

WORKDIR ${ORACLE_HOME}

CMD ["/u01/oracle/container-scripts/createOrStartInfraDomain.sh"]
