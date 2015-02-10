# LICENSE CDDL 1.0 + GPL 2.0
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for WebLogic 10.3.6 (Full) Generic Distribution
#
# REQUIRED BASE IMAGE TO BUILD THIS IMAGE
# ---------------------------------------
# Make sure you have oraclelinux:6.5 Docker image installed.
# Visit for more info:
# - http://public-yum.oracle.com/docker-images/
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) wls1036_linux32.bin
# Download the Generic installer from  http://www.oracle.com/technetwork/middleware/weblogic/downloads/wls1036_linux32.bin

#
# (2) jdk-6u45-linux-i586-rpm.bin
# Download from http://www.oracle.com/technetwork/java/javase/downloads/java-archive-downloads-javase6-419409.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
# $ sudo docker build -t oracleweblogic:10.3.6
#
# Pull base image
# ---------------
FROM oraclelinux:6

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# Environment variables required for this build (do NOT change)
ENV JAVA_RPM jdk-7u75-linux-x64.rpm 
ENV WLS_PKG wls1036_generic.jar
ENV SILENT_XML silent.xml
ENV BEA_HOME /u01/oracle/weblogic

# WLS Admin Password (you may change)
# This password is used for:
# (a) 'oracle' Linux user in this image
# -----------------------------------
ENV ADMIN_PASSWORD welcome1

# Install and configure Oracle JDK
# -------------------------------------
ADD $JAVA_RPM /root/
RUN rpm -ivh /root/$JAVA_RPM && \
    rm /root/$JAVA_RPM
ENV JAVA_HOME /usr/java/default
ENV CONFIG_JVM_ARGS -Djava.security.egd=file:/dev/./urandom

# Setup required packages (unzip), filesystem, and oracle user
# ------------------------------------------------------------
# Setup filesystem and oracle user
# ------------------------------------------------------------
# Enable this if behind proxy
RUN mkdir /u01 && chmod a+xr /u01 && \
    useradd -b /u01 -m -s /bin/bash oracle && \
    echo oracle:$ADMIN_PASSWORD | chpasswd

# Add files required to build this image
ADD $WLS_PKG /u01/
ADD setup/* /u01/

# Adjust file permissions, go to /u01 as user 'oracle' to proceed with WLS installation
RUN chown oracle:oracle -R /u01
WORKDIR /u01
USER oracle

# Installation of Weblogic
RUN  java -jar $WLS_PKG -mode=silent -silent_xml=$SILENT_XML && \
     rm $WLS_PKG $SILENT_XML 
RUN chown oracle:oracle -R /u01
USER oracle

# Define default command to start bash.
CMD ["/bin/bash"]
