# LICENSE CDDL 1.0 + GPL 2.0
#
# OPTARE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for OCCAS 7.0
# 
# IMPORTANT
# ---------
# The resulting image of this Dockerfile DOES NOT contain a OCCAS Domain.
# For that, look into the folder 'samples' for an example on how
# to create a domain on a new inherited image.
#
# You can go into 'samples/70-domain' after building the generic raw image
# and build that image, for example:
# 
#   $ cd samples/70-domain
#   $ sudo docker build -t myoccas .
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) occas_generic.jar
#     Download the Generic installer from https://edelivery.oracle.com/osdc/faces/Home.jspx
#
# (2) jdk-8u31-linux-x64.rpm
#     Download from http://www.oracle.com/technetwork/java/javase/downloads/java-archive-javase8-2177648.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ sudo docker build -t oracle/occas:7.0 .
#
# Pull base image
# ---------------
FROM oraclelinux:6.6

# Maintainer
# ----------
MAINTAINER Anton R. Yuste <ayuste@optaresolutions.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV JAVA_RPM jdk-8u31-linux-x64.rpm
ENV OCCAS_PKG occas_generic.jar
ENV JAVA_HOME /usr/java/default
ENV CONFIG_JVM_ARGS -Djava.security.egd=file:/dev/./urandom
ENV JAVA_OPTIONS -Djava.security.egd=file:/dev/./urandom

# Setup required packages (unzip), filesystem, and oracle user
# ------------------------------------------------------------
RUN mkdir /u01 && \
    chmod a+xr /u01 && \
    useradd -b /u01 -m -s /bin/bash oracle 

# Copy packages
COPY $OCCAS_PKG /u01/
COPY $JAVA_RPM /u01/
COPY install.file /u01/
COPY oraInst.loc /u01/

# Install and configure Oracle JDK 8u31
# -------------------------------------
RUN rpm -i /u01/$JAVA_RPM && \ 
    rm /u01/$JAVA_RPM

# Change the open file limits in /etc/security/limits.conf
RUN sed -i '/.*EOF/d' /etc/security/limits.conf && \
    echo "* soft nofile 16384" >> /etc/security/limits.conf && \ 
    echo "* hard nofile 16384" >> /etc/security/limits.conf && \ 
    echo "# EOF"  >> /etc/security/limits.conf

# Change the kernel parameters that need changing.
RUN echo "net.core.rmem_max=4192608" > /u01/oracle/.sysctl.conf && \
    echo "net.core.wmem_max=4192608" >> /u01/oracle/.sysctl.conf && \ 
    sysctl -e -p /u01/oracle/.sysctl.conf

# Adjust file permissions, go to /u01 as user 'oracle' to proceed with OCCAS installation
RUN chown oracle:oracle -R /u01
WORKDIR /u01
USER oracle

# Installation of OCCAS
RUN mkdir /u01/oracle/.inventory
RUN java -jar $OCCAS_PKG -ignoreSysPrereqs -novalidation -silent -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME && \
    rm $OCCAS_PKG /u01/oraInst.loc /u01/install.file

WORKDIR /u01/oracle/

ENV PATH $PATH:/u01/oracle/occas/oracle_common/common/bin

# Define default command to start bash. 
CMD ["bash"]
