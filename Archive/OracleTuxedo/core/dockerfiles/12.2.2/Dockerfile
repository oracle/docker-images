#
# Dockerfile template for Tuxedo 12.2.2
# 
# Download the following files to an empty directory:
#   tuxedo122200_64_Linux_01_x86.zip http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html
#

# Pull base image
FROM oracle/serverjre:8

MAINTAINER Judy Liu <judy.liu@oracle.com>

# Common environment variables required for this build (do NOT change)
# --------------------------------------------------------------------
ENV ORACLE_HOME=/u01/oracle \
    JAVA_HOME=/usr/java/default \
    PATH=/usr/java/default/bin:$PATH \
    TUX_PKG=tuxedo122200_64_Linux_01_x86.zip

# Core install doesn't include unzip or gcc, add them
# Setup filesystem and oracle user
# Adjust file permissions, go to /u01 as user 'oracle' to proceed with WLS installation
# ------------------------------------------------------------
RUN yum -y install unzip gcc file hostname which util-linux && rm -rf /var/cache/yum && \
    mkdir -p /u01 && chmod a+xr /u01 && \
    groupadd -g 1000 oracle && useradd -b /u01 -m -g oracle -u 1000 -s /bin/bash oracle 

# Copy packages
# -------------
COPY tuxedo12.2.2.rsp $TUX_PKG init.sh oraInst.loc /u01/ 
RUN  mv /u01/init.sh /u01/oracle/init.sh && \
     mv /u01/oraInst.loc /etc/ && \
     chown oracle:oracle -R /u01 && \
     chmod +x /u01/oracle/init.sh
USER oracle

# Install Tuxedo
# ------------------------------------------------------------
RUN cd /u01 && \
      mkdir oraInventory && \
      jar xf $TUX_PKG && \
      cd /u01/Disk1/install && \
      chmod -R +x * && \
      ./runInstaller.sh -responseFile /u01/tuxedo12.2.2.rsp -silent -waitforcompletion && \
      rm -rf /u01/Disk1 \
             /u01/tuxedo12.2.2.rsp \
             /u01/$TUX_PKG

ENV ORACLE_HOME=/u01/oracle/tuxHome
ENV TUXDIR=/u01/oracle/tuxHome/tuxedo12.2.2.0.0
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

# Define ENTRYPOINT. 
ENTRYPOINT ["/u01/oracle/init.sh"]
