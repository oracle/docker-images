# LICENSE CDDL 1.0 + GPL 2.0
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for WebLogic 10.3.6 ZIP Distro
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) wls1036_dev.zip
# Download from http://www.oracle.com/technetwork/middleware/weblogic/downloads/index.html
#
# (2) jdk-6u45-linux-amd64.rpm
# Download from http://www.oracle.com/technetwork/java/javase/downloads/java-archive-downloads-javase6-419409.html#jdk-6u45-oth-JPR
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#       $ sudo docker build -t oracle/weblogic:10.3.6-dev .
#
# DOCKER SCRIPTS FOR BUILDING/RUNNING WEBLOGIC
# --------------------------------------------
# You can also use the scripts provided in the folder ../bin to build and run WebLogic on Docker.
# Example building:
#   $ sudo buildDockerImage.sh -d
#
# Example running:
#   $ sudo dockWebLogic.sh -d
#
# For usage, provide argument '-h' for any of three scripts (dock*, and build)
#
# Pull base image
# ---------------
FROM oraclelinux:6

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# Environment variables required for this build (do NOT change)
ENV JAVA_RPM jdk-7u75-linux-x64.rpm
ENV WLS_PKG wls1036_dev.zip

# WLS Admin Password (you may change)
# This password is used for:
# (a) 'weblogic' admin user of WebLogic
# (b) 'oracle' Linux user in this image
# -----------------------------------
ENV ADMIN_PASSWORD welcome1

# Install and configure Oracle JDK
# -------------------------------------
ADD $JAVA_RPM /root/
RUN rpm -ivh /root/$JAVA_RPM && \
rm /root/$JAVA_RPM
ENV JAVA_HOME /usr/java/default
ENV CONFIG_JVM_ARGS -Djava.security.egd=file:/dev/./urandom
ENV MW_HOME /u01/oracle/weblogic
ENV MEM_ARGS "-Xms256m -Xmx512m -XX:MaxPermSize=256m"
ENV LD_LIBRARY_PATH /u01/oracle/weblogic/wlserver/server/native/linux/x86_64

# Setup filesystem and oracle user
# ------------------------------------------------------------
# Enable this if behind proxy
RUN mkdir /u01 && chmod a+xr /u01 && \
    useradd -b /u01 -m -s /bin/bash oracle && \
    echo oracle:$ADMIN_PASSWORD | chpasswd

# Add files required to build this image
ADD $WLS_PKG /u01/
ADD container-scripts/* /u01/
RUN mv /u01/add-machine.py /u01/createMachine.sh /u01/oracle/ && \
    chmod a+xr /u01/oracle/createMachine.sh
RUN mkdir /u01/oracle/weblogic && chmod a+xr /u01/oracle/weblogic 
RUN mv /u01/$WLS_PKG /u01/oracle/weblogic

# Adjust file permissions, go to /u01 as user 'oracle' to proceed with WLS installation
RUN chown oracle:oracle -R /u01
WORKDIR /u01/oracle/weblogic
USER oracle

# Installation of Weblogic
RUN jar xf /u01/oracle/weblogic/$WLS_PKG
RUN chown oracle:oracle -R /u01
RUN sh configure.sh -silent
RUN find /u01/oracle/weblogic -name "*.sh" -exec chmod a+x {} \;
RUN /u01/oracle/weblogic/wlserver/common/bin/wlst.sh -skipWLSModuleScanning /u01/create-wls-domain.py && \
    mkdir -p /u01/oracle/weblogic/user_projects/domains/base_domain/servers/AdminServer/security && \
    echo "username=weblogic" > /u01/oracle/weblogic/user_projects/domains/base_domain/servers/AdminServer/security/boot.properties && \
    echo "password=$ADMIN_PASSWORD" >> /u01/oracle/weblogic/user_projects/domains/base_domain/servers/AdminServer/security/boot.properties && \
    echo "export MEM_ARGS=${MEM_ARGS}"  >> /u01/oracle/weblogic/user_projects/domains/base_domain/bin/setDomainEnv.sh && \
    echo "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"  >> /u01/oracle/weblogic/user_projects/domains/base_domain/bin/setDomainEnv.sh && \
    rm /u01/create-wls-domain.py /u01/oracle/weblogic/$WLS_PKG 

# Expose Node Manager default port, and also default http/https ports for admin console
EXPOSE 5556 7001 7002

# Make sure root has also right PATH and WLS environment variables configured
USER root
RUN echo ". /u01/oracle/weblogic/wlserver/server/bin/setWLSEnv.sh" >> /root/.bashrc 
RUN echo ". /u01/oracle/weblogic/user_projects/domains/base_domain/bin/setDomainEnv.sh" >> /root/.bashrc && \
    echo "export PATH=$PATH:/u01/oracle/weblogic/wlserver/common/bin:/u01/oracle/weblogic/user_projects/domains/base_domain/bin" >> /root/.bashrc 

WORKDIR /u01/oracle
USER oracle

# Define default command to start bash.
CMD ["/u01/oracle/weblogic/user_projects/domains/base_domain/bin/startWebLogic.sh"]
