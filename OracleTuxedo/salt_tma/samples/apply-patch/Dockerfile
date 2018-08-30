# LICENSE UPL 1.0
#
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# Oracle Tuxedo 12.2.2 Rolling Patch: e.g. p24444780_122200_Linux-x86-64.zip
# * Example download link for RP003: https://updates.oracle.com/Orion/Services/download/p24444780_122200_Linux-x86-64.zip?aru=20506667&patch_file=p24444780_122200_Linux-x86-64.zip
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put the downloaded RP package in the same directory as this Dockerfile
# Run:
#      $ docker build -t oracle/tuxedoall:12.2.2.1 .

# Pull base image
# ---------------
FROM oracle/tuxedoall:latest

# Common environment variables required for this build (do NOT change)
# ------------------------------------------------------------
ENV RP_PKG=p24444780_122200_Linux-x86-64.zip \
    ORACLE_HOME=/u01/oracle/tuxHome

# Copy all the files needed by the installation to the container
# ------------------------------------------------------------
USER root
COPY $RP_PKG init.sh /u01/
RUN  mv /u01/init.sh /u01/oracle/init.sh && \
     chown oracle:oracle -R /u01 && \
     chmod +x /u01/oracle/init.sh

# Apply Rolling Patch
# ------------------------------------------------------------
USER oracle
RUN  cd /u01 && \
     mkdir tmp && cd tmp && \
     unzip /u01/$RP_PKG && \
     manager_patch=`find . -name *.zip` && \
     $ORACLE_HOME/OPatch/opatch apply $manager_patch && \
     rm -rf /u01/tmp /u01/$RP_PKG

# Set working directory
WORKDIR /u01/oracle
# Define ENTRYPOINT
ENTRYPOINT ["/u01/oracle/init.sh"]
