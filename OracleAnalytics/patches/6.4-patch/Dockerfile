# Copyright (c) 2022 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle Analytics Server 6.4, and applies necessary
# patches required.

# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) p34080315_122140_Generic.zip
# (2) p33958532_122140_Generic.zip
# (3) p34044738_122140_Generic.zip
# (4) p32784652_122140_Generic.zip
# (5) p30613424_122140_Generic.zip
# (6) p31403376_122140_Generic.zip
# (7) p33618954_122140_Generic.zip
# (8) p33546536_12214211129_Generic.zip
# (9) p32575741_122140_Linux-x86-64.zip
# (10) p33950717_122140_Generic.zip
# (11) p34065178_122140_Generic.zip

#     Download the patches from https://support.oracle.com
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ docker build --force-rm=true --no-cache=true -t oracle/fmw-infrastructure:12.2.1.4-patched-for-oas64 .
#

# Pull base image
# ---------------
FROM oracle/analyticsserver:6.4

# Labels
# ------
LABEL "maintainer"="Padam Bengani <padam.bengani@oracle.com>"

#Common ENV
#-----------
ENV OPATCH_NO_FUSER=true

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV PATCH_PKG_34080315="p34080315_122140_Generic.zip" \
    PATCH_PKG_33958532="p33958532_122140_Generic.zip" \
    PATCH_PKG_34044738="p34044738_122140_Generic.zip" \
    PATCH_PKG_32784652="p32784652_122140_Generic.zip" \
    PATCH_PKG_30613424="p30613424_122140_Generic.zip" \
    PATCH_PKG_31403376="p31403376_122140_Generic.zip" \
    PATCH_PKG_33618954="p33618954_122140_Generic.zip" \
    PATCH_PKG_33546536="p33546536_12214211129_Generic.zip" \
    PATCH_PKG_32575741="p32575741_122140_Linux-x86-64.zip" \
    PATCH_PKG_33950717="p33950717_122140_Generic.zip" \
    PATCH_PKG_34065178="p34065178_122140_Generic.zip"


# Copy supplemental package and scripts
# --------------------------------
COPY --chown=oracle:oracle $PATCH_PKG_34080315 $PATCH_PKG_33958532 $PATCH_PKG_34044738 $PATCH_PKG_32784652 $PATCH_PKG_30613424 $PATCH_PKG_31403376 $PATCH_PKG_33618954 $PATCH_PKG_33546536 $PATCH_PKG_32575741 $PATCH_PKG_33950717 $PATCH_PKG_34065178 /u01/

# Installation of Supplemental Quick Installer
# --------------------------------------------
USER oracle

RUN unzip "/u01/$PATCH_PKG_34080315" -d /u01 && \
    chmod +x /u01/WLS_SPB_12.2.1.4.220418/tools/spbat/generic/SPBAT/spbat.sh && \
    /u01/WLS_SPB_12.2.1.4.220418/tools/spbat/generic/SPBAT/spbat.sh -phase apply -oracle_home "$ORACLE_HOME" && \
    rm "/u01/$PATCH_PKG_34080315" && \
    unzip "/u01/$PATCH_PKG_33958532" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/33958532 && \
    rm "/u01/$PATCH_PKG_33958532" && \
    unzip "/u01/$PATCH_PKG_34044738" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/34044738 && \
    rm "/u01/$PATCH_PKG_34044738" && \
    unzip "/u01/$PATCH_PKG_32784652" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/32784652 && \
    rm "/u01/$PATCH_PKG_32784652" && \
    unzip "/u01/$PATCH_PKG_30613424" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/30613424 && \
    rm "/u01/$PATCH_PKG_30613424" && \
    unzip "/u01/$PATCH_PKG_31403376" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/31403376 && \
    rm "/u01/$PATCH_PKG_31403376" && \
    unzip "/u01/$PATCH_PKG_33618954" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/33618954 && \
    rm "/u01/$PATCH_PKG_33618954" && \
    unzip "/u01/$PATCH_PKG_33546536" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/33546536 && \
    rm "/u01/$PATCH_PKG_33546536" && \
    unzip "/u01/$PATCH_PKG_32575741" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/32575741 && \
    rm "/u01/$PATCH_PKG_32575741" && \
    unzip "/u01/$PATCH_PKG_33950717" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/33950717 && \
    rm "/u01/$PATCH_PKG_33950717" && \
    unzip "/u01/$PATCH_PKG_34065178" -d /u01 && \
    "$ORACLE_HOME/OPatch/opatch" apply -silent /u01/34065178 && \
    rm "/u01/$PATCH_PKG_34065178"

WORKDIR ${ORACLE_HOME}

CMD ["/u01/createAndStartDomain.sh"]
