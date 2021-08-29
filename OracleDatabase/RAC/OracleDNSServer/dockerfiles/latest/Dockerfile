# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Database 19c RAC Storage Server. This file create DNS Server for RAC. 
# 
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build -t oracle/rac-dns-server:19.3.0. 
#
# Pull base image
# ---------------
FROM oraclelinux:7-slim

# Maintainer
# ----------
MAINTAINER Paramdeep saini <paramdeep.saini@oracle.com>, Sanjay Singh <sanjay.singh@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
# Linux Env Variable
ENV SETUP_LINUX_FILE="setupLinuxEnv.sh" \
    INSTALL_DIR="/opt/scripts" \
    ZONEFILE="zonefile" \
    REVERSE_ZONE_FILE="reversezonefile" \
    NAMED_SAMPLE_FILE="named.rfc1912.zones" \
    NAMED_CONF_FILE="named.conf" \
    NAMED_CHROOT_ETC_DIR="/var/named/chroot/etc" \
    NAMED_CHROOT_ROOT_DIR="/var/named/chroot" \
    CONFIG_DNS_SERVER_FILE="setupDNSServer.sh" \
    ZONE_FILE_LOC_1="/var/named" \
    ZONE_FILE_LOC_2="/var/named/chroot/var/named/" \
    NAMED_LOCALHOST_FILE="named.localhost" \
    NAMED_LOOPBACK_FILE="named.loopback" \
    NAMED_EMPTY_FILE="named.empty" \
    FUNCTIONS="functions.sh" \
    RUN_FILE="runOracle.sh" \
    SUDO_SETUP_FILE="setupSudo.sh" \ 
    BIN="/usr/sbin" \
    ORADATA="/oradata" \
    container="true" 
# Use second ENV so that variable get substituted
ENV  INSTALL_SCRIPTS=$INSTALL_DIR/install  \
     SCRIPT_DIR=$INSTALL_DIR/startup

# Copy binaries
# -------------
# Copy Linux setup Files
COPY $SETUP_LINUX_FILE $INSTALL_SCRIPTS/

# Setup Scripts
COPY $RUN_FILE $ZONEFILE $REVERSE_ZONE_FILE $NAMED_SAMPLE_FILE $FUNCTIONS $NAMED_LOOPBACK_FILE $NAMED_EMPTY_FILE $NAMED_LOCALHOST_FILE $CONFIG_DNS_SERVER_FILE $NAMED_CONF_FILE $SCRIPT_DIR/

COPY $SETUP_LINUX_FILE $SUDO_SETUP_FILE $INSTALL_DIR/install/

RUN  chmod 755 $INSTALL_DIR/install/*.sh && \
     $INSTALL_DIR/install/$SETUP_LINUX_FILE && \
     $INSTALL_DIR/install/$SUDO_SETUP_FILE  && \
     sync  && \
     rm -rf $INSTALL_DIR/install && \
     chmod 755 $SCRIPT_DIR/*.sh && \
     chmod 666 $SCRIPT_DIR/$ZONEFILE && \
     chmod 666 $SCRIPT_DIR/$REVERSE_ZONE_FILE && \
     chmod 666 $SCRIPT_DIR/$NAMED_SAMPLE_FILE && \
     echo "nohup $SCRIPT_DIR/runOracle.sh &" >> /etc/rc.local && \
     chmod +x /etc/rc.d/rc.local  && \
     useradd orcladmin && \
     sync

# Define default command to start Oracle Database.
USER orcladmin
WORKDIR /home/orcladmin

#CMD ["/usr/sbin/init"]
CMD exec $SCRIPT_DIR/$RUN_FILE
