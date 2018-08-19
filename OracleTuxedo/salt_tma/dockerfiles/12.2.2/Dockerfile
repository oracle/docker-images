
# LICENSE UPL 1.0
#
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) Oracle Tuxedo Mainframe Adapter for SNA 12cR2 (12.2.2) GA Installer: tmasna122200_64_linux_x86_64.zip
#     Download from http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html
#
# (1) Oracle Tuxedo Mainframe Adapter for TCP 12cR2 (12.2.2) GA Installer: tmatcp122200_64_linux_x86_64.zip
#     Download from http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Run:
#      $ docker build -t oracle/tuxedoalltma:12.2.2.1 .
#
# Pull base image from Oracle Tuxedo SALT docker image
FROM oracle/tuxedoall:12.2.2.1

# Common environment variables required for this build (do NOT change)
# ------------------------------------------------------------
ENV ORACLE_HOME=/u01/oracle/tuxHome \
    TUXDIR=/u01/oracle/tuxHome/tuxedo12.2.2.0.0 \
    JAVA_HOME=/usr/java/default \
    PATH=/usr/java/default/bin:$PATH \
    TMASNA_PKG=tmasna122200_64_linux_x86_64.zip \
    TMATCP_PKG=tmatcp122200_64_linux_x86_64.zip

# Copy all the files needed by the installation to the container
# ------------------------------------------------------------
USER root
COPY $TMASNA_PKG $TMATCP_PKG init.sh tmasna12.2.2.rsp tmatcp12.2.2.rsp /u01/
RUN  mv /u01/init.sh /u01/oracle/init.sh && \
     chown oracle:oracle -R /u01 && \
     chmod +x /u01/oracle/init.sh

# Install Tuxedo TMA SNA and TCP
# ------------------------------------------------------------
USER oracle
RUN  cd /u01 && \
     jar xf $TMASNA_PKG && \
     chmod -R +x /u01/Disk1/install/* && \
     /u01/Disk1/install/runInstaller.sh -responseFile /u01/tmasna12.2.2.rsp -silent -waitforcompletion && \
     rm -rf /u01/Disk1 /u01/tmasna12.2.2.rsp /u01/$TMASNA_PKG && \
     jar xf $TMATCP_PKG && \
     chmod -R +x /u01/Disk1/install/* && \
     /u01/Disk1/install/runInstaller.sh -responseFile /u01/tmatcp12.2.2.rsp -silent -waitforcompletion && \
     rm -rf /u01/Disk1 /u01/tmatcp12.2.2.rsp /u01/$TMATCP_PKG

# Set working directory
WORKDIR /u01/oracle
# Define ENTRYPOINT
ENTRYPOINT ["/u01/oracle/init.sh"]
