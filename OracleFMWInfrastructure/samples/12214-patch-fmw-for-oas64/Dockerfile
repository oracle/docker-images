# LICENSE UPL 1.0
#
# Copyright (c) 2022 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle FMW Infrastructure image (12.2.1.4), and applies necessary
# patches required for Oracle Analytics Server 6.4.

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

#     Download the patches from http://support.oracle.com
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ docker build --force-rm=true --no-cache=true -t oracle/fmw-infrastructure:12.2.1.4-patched-for-oas64 .
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
COPY --chown=oracle:oracle $PATCH_PKG_34080315 /u01/
COPY --chown=oracle:oracle $PATCH_PKG_33958532 /u01/
COPY --chown=oracle:oracle $PATCH_PKG_34044738 /u01/
COPY --chown=oracle:oracle $PATCH_PKG_32784652 /u01/
COPY --chown=oracle:oracle $PATCH_PKG_30613424 /u01/
COPY --chown=oracle:oracle $PATCH_PKG_31403376 /u01/
COPY --chown=oracle:oracle $PATCH_PKG_33618954 /u01/
COPY --chown=oracle:oracle $PATCH_PKG_33546536 /u01/
COPY --chown=oracle:oracle $PATCH_PKG_32575741 /u01/
COPY --chown=oracle:oracle $PATCH_PKG_33950717 /u01/
COPY --chown=oracle:oracle $PATCH_PKG_34065178 /u01/

# Installation of Supplemental Quick Installer
# --------------------------------------------
USER oracle

RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG_34080315 && cd - && \
    cd /u01/WLS_SPB_12.2.1.4.220418/tools/spbat/generic/SPBAT && chmod +x ./spbat.sh && ./spbat.sh -phase apply -oracle_home $ORACLE_HOME && \
    rm /u01/$PATCH_PKG_34080315

RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG_33958532 && cd - && \
    cd /u01/33958532 && $ORACLE_HOME/OPatch/opatch apply -silent && \
    rm /u01/$PATCH_PKG_33958532

RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG_34044738 && cd - && \
    cd /u01/34044738 && $ORACLE_HOME/OPatch/opatch apply -silent && \
    rm /u01/$PATCH_PKG_34044738

RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG_32784652 && cd - && \
    cd /u01/32784652 && $ORACLE_HOME/OPatch/opatch apply -silent && \
    rm /u01/$PATCH_PKG_32784652

RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG_30613424 && cd - && \
    cd /u01/30613424 && $ORACLE_HOME/OPatch/opatch apply -silent && \
    rm /u01/$PATCH_PKG_30613424

RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG_31403376 && cd - && \
    cd /u01/31403376 && $ORACLE_HOME/OPatch/opatch apply -silent && \
    rm /u01/$PATCH_PKG_31403376

RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG_33618954 && cd - && \
    cd /u01/33618954 && $ORACLE_HOME/OPatch/opatch apply -silent && \
    rm /u01/$PATCH_PKG_33618954

RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG_33546536 && cd - && \
    cd /u01/33546536 && $ORACLE_HOME/OPatch/opatch apply -silent && \
    rm /u01/$PATCH_PKG_33546536

RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG_32575741 && cd - && \
    cd /u01/32575741 && $ORACLE_HOME/OPatch/opatch apply -silent && \
    rm /u01/$PATCH_PKG_32575741

RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG_33950717 && cd - && \
    cd /u01/33950717 && $ORACLE_HOME/OPatch/opatch apply -silent && \
    rm /u01/$PATCH_PKG_33950717

RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$PATCH_PKG_34065178 && cd - && \
    cd /u01/34065178 && $ORACLE_HOME/OPatch/opatch apply -silent && \
    rm /u01/$PATCH_PKG_34065178


WORKDIR ${ORACLE_HOME}


CMD ["/u01/oracle/container-scripts/createOrStartInfraDomain.sh"]
