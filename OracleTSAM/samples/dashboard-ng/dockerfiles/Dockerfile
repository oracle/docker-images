# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2017-2017 Oracle and/or its affiliates. All rights reserved.
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) Oracle Tuxedo 12.2.2 Rolling Patch: e.g. RP016 - p25391869_122200_Linux-x86-64.zip
#     Download from https://updates.oracle.com/Orion/Services/download/p25391869_122200_Linux-x86-64.zip?aru=21005987&patch_file=p25391869_122200_Linux-x86-64.zip
#
# (2) Oracle TSAM Plus 12.2.2 Rolling Patch: e.g. RP004 - p25530287_12220_Linux-x86-64.zip
#     Download from https://updates.oracle.com/Orion/Services/download/p25530287_12220_Linux-x86-64.zip?aru=21140450&patch_file=p25530287_12220_Linux-x86-64.zip
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ docker build -t oracle/tuxedo:12.2.2-4doms .

# Pull base image
# ---------------
FROM oracle/tuxedo:12.2.2

# Maintainer
# ----------
MAINTAINER Chris Guo <chris.guo@oracle.com>

# Common environment variables required for this build (do NOT change)
# --------------------------------------------------------------------
ENV PATH=$PATH:/usr/java/default/bin

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV TUX_RP_PKG=p*_122200_Linux-x86-64.zip \
    TSAM_RP_PKG=p*_12220_Linux-x86-64.zip \
    ORACLE_HOME=/home/oracle/tuxHome

USER root

# Copy files
# ----------
COPY $TUX_RP_PKG $TSAM_RP_PKG /home/oracle/
COPY files/app /home/oracle/app/
COPY files/init.sh /home/oracle/sbin/
COPY files/oraInst.loc /etc/

RUN chown -R oracle:oracle /home/oracle/app /home/oracle/sbin

USER oracle
WORKDIR /home/oracle

# Apply Rolling Patch
# ------------------------------------------------------------
RUN cd && ln -s $JAVA_HOME tuxHome/jdk && \
      mkdir tmp && cd tmp && \
      jar xf ../$TUX_RP_PKG && \
      /home/oracle/tuxHome/OPatch/opatch apply *.zip && \
      cd && rm -rf tmp $TUX_RP_PKG && \
      mkdir tmp && cd tmp && \
      jar xf ../$TSAM_RP_PKG && \
      agent_patch=`find . -name "*.zip" -size -10M` && \
      /home/oracle/tuxHome/OPatch/opatch apply $agent_patch && \
      cd && rm -rf tmp $TSAM_RP_PKG

# Define default command to start script.
ENTRYPOINT ["/home/oracle/sbin/init.sh"]

