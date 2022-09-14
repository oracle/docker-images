# LICENSE UPL 1.0
#
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# Oracle TSAM Plus 12.2.2 Rolling Patch: e.g. p25530287_12220_Linux-x86-64.zip
# * Example download link for RP004: https://updates.oracle.com/Orion/Services/download/p25530287_12220_Linux-x86-64.zip?aru=21140450&patch_file=p25530287_12220_Linux-x86-64.zip
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put the downloaded RP package in the same directory as this Dockerfile
# Run:
#      $ docker build -t oracle/tsam:12.2.2.1 .

# Pull base image
# ---------------
FROM oracle/tsam:12.2.2

# Maintainer
# ----------
MAINTAINER Chris Guo <chris.guo@oracle.com>

# Common environment variables required for this build (do NOT change)
# --------------------------------------------------------------------
ENV RP_PKG=p*_12220_Linux-x86-64.zip

# Copy packages
# -------------
COPY $RP_PKG /u01/

USER root
RUN if [ "`/bin/ls -l /u01/$RP_PKG|cut -c8`" != r ];then \
      chmod a+r /u01/$RP_PKG; \
    fi


# Apply Rolling Patch
# ------------------------------------------------------------
USER oracle
RUN cd /u01/oracle && \
      ln -s $JAVA_HOME oraHome/jdk && \
      mkdir tmp && cd tmp && \
      jar xf /u01/$RP_PKG && \
      manager_patch=`find . -size +10M` && \
      /u01/oracle/oraHome/OPatch/opatch apply $manager_patch && \
      cd && rm -rf tmp /u01/$RP_PKG && \
      sed -i "s?TSAMDeployer.jar:?TSAMDeployer.jar:/usr/lib/oracle/12.2/client64/lib/ojdbc8.jar:?" \
      /u01/oracle/oraHome/tsam12.2.2.0.0/deploy/DatabaseDeployer.sh

