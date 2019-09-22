# LICENSE UPL 1.0
#
# Copyright (c) 1982-2017 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for a patched Oracle Database 12c Release 1 Enterprise Edition
# 
# REQUIREMETNS FOR THIS IMAGE
# ----------------------------------
# The oracle/database:12.2.0.1-ee image has to exist
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put the downloaded patch(es) into the sub folders patch/0NN
# Run: 
#      $ docker build -f Dockerfile.ee -t oracle/database:12.2.0.1-ee-<patch level> . 
#
# Pull base image
# ---------------
FROM oracle/database-rac-patch:19.3.0

# Maintainer
# ----------
MAINTAINER Gerald Venzl <gerald.venzl@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
user root

ENV PATCH_DIR="patches" \
    GRID_PATCH_FILE="applyGridPatches.sh" \
    DB_PATCH_FILE="applyDBPatches.sh" \
    FIXUP_PREQ_FILE="fixupPreq.sh" \
    DB_USER="oracle" \
    GRID_USER="grid"  

# Use second ENV so that variable get substituted
ENV PATCH_INSTALL_DIR=/tmp/patches


# Copy binaries
# -------------
COPY $PATCH_DIR $PATCH_INSTALL_DIR/

# Install patches
RUN chown -R grid:oinstall $PATCH_INSTALL_DIR/*.sh && \ 
    chmod ug+x $PATCH_INSTALL_DIR/*.sh && \
    chmod ug+rwx $PATCH_INSTALL_DIR && \
    chown -R grid:oinstall $PATCH_INSTALL_DIR && \
    sed -e '/hard *memlock/s/^/#/g' -i /etc/security/limits.conf  && \
    sync && \
    su grid -c "$PATCH_INSTALL_DIR/$GRID_PATCH_FILE $PATCH_INSTALL_DIR" && \
    chown -R oracle:oinstall $PATCH_INSTALL_DIR && \
    su oracle -c "$PATCH_INSTALL_DIR/$DB_PATCH_FILE $PATCH_INSTALL_DIR" && \
    $PATCH_INSTALL_DIR/$FIXUP_PREQ_FILE  && \
    rm -rf /etc/oracle && \
    rm -rf $PATCH_INSTALL_DIR

USER grid 
WORKDIR /home/grid
VOLUME ["/common_scripts"]

# Define default command to start Oracle Grid and RAC Database setup.

CMD ["/usr/sbin/oracleinit"]
