#
# Dockerfile template for Tuxedo 12.1.3
# 
# Download the following files to an empty directory:
#   tuxedo121300_64_Linux_01_x86.zip http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html
#   p22090512_121300_Linux-x86-64.zip 	or whatever the latest Tuxedo rolling patch is from My Oracle Support
#

# Pull base image
FROM oracle/serverjre:8

MAINTAINER Judy Liu <judy.liu@oracle.com>

# Common environment variables required for this build (do NOT change)
# --------------------------------------------------------------------
ENV ORACLE_HOME=/u01/oracle \
    PATH=/usr/java/default/bin:$PATH \
    TUX_PKG=tuxedo121300_64_Linux_01_x86.zip

# Core install doesn't include unzip or gcc, add them
# Setup filesystem and oracle user
# Adjust file permissions, go to /u01 as user 'oracle' to proceed with WLS installation
# ------------------------------------------------------------
RUN yum -y install unzip gcc file hostname which && yum -y clean all && \
    mkdir -p /u01 && chmod a+xr /u01 && \
    groupadd -g 1000 oracle && useradd -b /u01 -m -g oracle -u 1000 -s /bin/bash oracle 

# Copy packages
# -------------
COPY tuxedo12.1.3.rsp $TUX_PKG /u01/
COPY oraInst.loc /etc/
RUN  chown oracle:oracle -R /u01
USER oracle

# Install Tuxedo
# ------------------------------------------------------------
RUN cd /u01 && \
      mkdir oraInventory && \
      jar xf $TUX_PKG && \
      cd /u01/Disk1/install && \
      chmod -R +x * && \
      ./runInstaller -responseFile /u01/tuxedo12.1.3.rsp -silent -waitforcompletion && \
      rm -rf /u01/Disk1 \
             /u01/tuxedo12.1.3.rsp \
             /u01/$TUX_PKG

ENV ORACLE_HOME=/u01/oracle/tuxHome
ENV TUXDIR /u01/oracle/tuxHome/tuxedo12.1.3.0.0
ENV PATH=$PATH:$TUXDIR/bin \
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TUXDIR/lib

#
# Configure network ports
# tlisten	nlsaddr:5001  jmx:5002
# SALT 		http:5010
# WSL		5020
#EXPOSE 5001 5002 5010 5020
#USER root
#RUN yum -y install bind-utils

USER oracle
WORKDIR /u01/oracle
