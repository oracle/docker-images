# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for a patched Oracle Database 21c Release 3
#
# REQUIREMETNS FOR THIS IMAGE
# ----------------------------------
# The oracle/rac-database:21.3.0 image has to exist
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put the downloaded patch(es) into the sub folders patch/0NN
# Run:
#      $ docker build -f Dockerfile -t oracle/rac-database:21.3.0-<patch level> .
#
# hadolint global ignore=DL3006,DL3025
ARG BASE_GSM_IMAGE=localhost/oracle/database-gsm:19.3.0
ARG GSM_SLIM_IMAGE="oraclelinux:8"

# Pull base image
# ---------------
FROM ${BASE_GSM_IMAGE} as builder

# Argument to control removal of components not needed after db software installation
ARG PATCH_DIR="patches"
ARG USER="root"
ARG WORKDIR="/home/oracle"

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------

USER $USER

ENV GSM_PATCH_FILE="applyGSMPatches.sh" \
    PATCH_INSTALL_DIR=/tmp/patches \
    PATCH_DIR=$PATCH_DIR \
    WORKDIR=$WORKDIR \
    USER=$USER \
    GSM_USER="oracle" 

RUN mkdir $PATCH_INSTALL_DIR

# Copy binaries
# -------------
COPY $PATCH_DIR $PATCH_INSTALL_DIR/

# Install patches
RUN chown -R oracle:oinstall $PATCH_INSTALL_DIR/*.sh && \
    chmod ug+x $PATCH_INSTALL_DIR/*.sh && \
    chmod ug+rwx $PATCH_INSTALL_DIR/ && \
    chown -R oracle:oinstall $PATCH_INSTALL_DIR && \
    sed -e '/hard *memlock/s/^/#/g' -i /etc/security/limits.conf  && \
    sed -e '/ *nofile /s/^/#/g' -i /etc/security/limits.conf  && \
    sync

USER oracle

RUN $PATCH_INSTALL_DIR/$GSM_PATCH_FILE $PATCH_INSTALL_DIR
# hadolint ignore=DL3002
USER root
# hadolint ignore=SC2086
RUN rm -rf /etc/oracle && \
    rm -rf "$PATCH_INSTALL_DIR"  && \
    rm -rf $PATCH_DIR/* $ORACLE_HOME/.patch_storage $ORACLE_HOME/.opatchauto_storage

#####################
FROM ${GSM_SLIM_IMAGE} AS final
ARG GSM_HOME=/u01/app/oracle/product/19c/gsmhome_1
ARG PREINSTALL_PKG=oracle-database-preinstall-19c
ARG WORKDIR="/home/oracle"

LABEL "provider"="Oracle"                                          \
      "issues"="https://github.com/oracle/docker-images"       \
      "volume.setup.location1"="/opt/oracle/scripts"              \
      "port.listener"="1522"

ENV  GSM_BASE="/u01/app/oracle" \
     INVENTORY="/u01/app/oracle/oraInventory" \
     INSTALL_DIR="/opt/oracle/scripts" \
     RUN_FILE="runOracle.sh" \
     MAINPY="main.py" \
     PYTHON_FILE="/usr/bin/python" \
     PYTHON3_FILE="/usr/bin/python3" \
     WORKDIR=$WORKDIR \
     CHECKLIVENESS="checkLiveness.sh"

# hadolint ignore=DL3044
ENV  INSTALL_SCRIPTS=$INSTALL_DIR/install \
     ORACLE_HOME=$GSM_HOME \
     ORACLE_BASE=$GSM_BASE \
     SCRIPT_DIR=$INSTALL_DIR/sharding \
     PATH=/bin:/usr/bin:/sbin:/usr/sbin \
     GSM_PATH=$GSM_HOME/bin:$PATH \
     GSM_LD_LIBRARY_PATH=$GSM_HOME/lib:/usr/lib:/lib

USER root
# hadolint ignore=DL3032,DL3033
RUN  yum -y install $PREINSTALL_PKG  net-tools which zip unzip tar openssl openssh-server vim-minimal which vim-minimal passwd sudo policycoreutils-python-utils python3 && \
     sed -e '/hard *memlock/s/^/#/g' -i /etc/security/limits.conf  && \
     sed -e '/ *nofile /s/^/#/g' -i /etc/security/limits.conf  && \
     sed -e '/hard *memlock/s/^/#/g' -i /etc/security/limits.d/${PREINSTALL_PKG}.conf && \
     sed -e '/ *nofile /s/^/#/g' -i /etc/security/limits.d/${PREINSTALL_PKG}.conf && \
     chmod 666 /etc/sudoers && \
     echo "oracle       ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers  && \
     chmod 440 /etc/sudoers

USER oracle
COPY --from=builder /u01 /u01
COPY --from=builder /opt/oracle /opt/oracle
COPY --from=builder /home/oracle/.bashrc  /home/oracle/.bashrc

USER root
RUN if [ ! -f $PYTHON_FILE ]; then \
      ln -s $PYTHON3_FILE $PYTHON_FILE && \
      :; \
    fi

USER root
RUN $INVENTORY/orainstRoot.sh && \
    $GSM_HOME/root.sh && \
    sync

USER oracle
WORKDIR $WORKDIR
VOLUME ["$GSM_BASE/oradata"]

HEALTHCHECK --interval=2m --start-period=25m \
   CMD "$SCRIPT_DIR/scripts/$CHECKLIVENESS" >/dev/null || exit 1

# Define default command to start Oracle Database setup.

CMD exec $SCRIPT_DIR/$RUN_FILE
