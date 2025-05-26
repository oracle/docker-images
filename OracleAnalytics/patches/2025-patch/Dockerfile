# Copyright (c) 2025 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle Analytics Server 2025 (8.2), and applies necessary
# patches required.

# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) p37804819_122140_Generic.zip
# (2) p34809489_122140_Generic.zip
# (3) p36649916_122140_Generic.zip
# (4) p37284722_122140_Generic.zip
# (5) p37684007_122140_Generic.zip
# (6) p36316422_122140_Generic.zip
# (7) p36946553_122140_Generic.zip
# (8) p37388935_122140_Generic.zip
# (9) p37526122_122140_Linux-x86-64.zip
# (10) p37665839_122140_Linux-x86-64.zip

#     Download the patches from https://support.oracle.com
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ docker build --force-rm=true --no-cache=true -t oracle/analyticsserver:2025-patch .
#

# Pull base image
# ---------------
FROM oracle/analyticsserver:2025

# Labels
# ------
LABEL "maintainer"="Padam Bengani <padam.bengani@oracle.com>"

# Install
#-------------------------------------------------------------
USER root

# tools for applying patches
RUN dnf install -y binutils make gcc glibc-devel && dnf clean all

# Common ENV
#-----------
ENV OPATCH_NO_FUSER=true

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV PATCH_PKG_37804819="p37804819_122140_Generic.zip" \
    PATCH_PKG_34809489="p34809489_122140_Generic.zip" \
    PATCH_PKG_36649916="p36649916_122140_Generic.zip" \
    PATCH_PKG_37284722="p37284722_122140_Generic.zip" \
    PATCH_PKG_37684007="p37684007_122140_Generic.zip" \
    PATCH_PKG_36316422="p36316422_122140_Generic.zip" \
    PATCH_PKG_36946553="p36946553_122140_Generic.zip" \
    PATCH_PKG_37388935="p37388935_122140_Generic.zip" \
    PATCH_PKG_37526122="p37526122_122140_Linux-x86-64.zip" \
    PATCH_PKG_37665839="p37665839_122140_Linux-x86-64.zip"

# Copy supplemental package and scripts
# --------------------------------
COPY --chown=oracle:oracle \
    $PATCH_PKG_37804819 $PATCH_PKG_34809489 $PATCH_PKG_36649916 $PATCH_PKG_37284722 \
    $PATCH_PKG_37526122 $PATCH_PKG_37684007 $PATCH_PKG_36316422 $PATCH_PKG_36946553 \
    $PATCH_PKG_37388935 $PATCH_PKG_37665839 /u01/

# Installation of Supplemental Quick Installer and Patches
# --------------------------------------------------------
USER oracle

RUN unzip "/u01/$PATCH_PKG_37804819" -d /u01 && \
    chmod +x /u01/WLS_SPB_12.2.1.4.250408/tools/spbat/generic/SPBAT/spbat.sh && \
    /u01/WLS_SPB_12.2.1.4.250408/tools/spbat/generic/SPBAT/spbat.sh -phase apply -oracle_home "$ORACLE_HOME" && \
    rm "/u01/$PATCH_PKG_37804819" && \
    unzip "/u01/$PATCH_PKG_34809489" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/34809489 && \
    rm "/u01/$PATCH_PKG_34809489" && \
    unzip "/u01/$PATCH_PKG_36649916" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/36649916 && \
    rm "/u01/$PATCH_PKG_36649916" && \
    unzip "/u01/$PATCH_PKG_37284722" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/37284722 && \
    rm "/u01/$PATCH_PKG_37284722" && \
    unzip "/u01/$PATCH_PKG_37684007" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/37684007 && \
    rm "/u01/$PATCH_PKG_37684007" && \
    unzip "/u01/$PATCH_PKG_36316422" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/36316422 && \
    rm "/u01/$PATCH_PKG_36316422" && \
    unzip "/u01/$PATCH_PKG_36946553" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/36946553 && \
    rm "/u01/$PATCH_PKG_36946553" && \
    unzip "/u01/$PATCH_PKG_37388935" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/37388935 && \
    rm "/u01/$PATCH_PKG_37388935" && \
    unzip "/u01/$PATCH_PKG_37526122" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/37526122 && \
    rm "/u01/$PATCH_PKG_37526122" && \
    unzip "/u01/$PATCH_PKG_37665839" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/36749613 && \
    rm "/u01/$PATCH_PKG_37665839"

WORKDIR ${ORACLE_HOME}

CMD ["/u01/createAndStartDomain.sh"]
