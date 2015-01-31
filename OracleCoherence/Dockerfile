# LICENSE CDDL 1.0 + GPL 2.0
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Coherence 12.1.3 Standalone Distribution
# 
# REQUIRED BASE IMAGE TO BUILD THIS IMAGE
# ---------------------------------------
# Make sure you have oraclelinux:7.0 Docker image installed.
# Visit for more info: 
#  - http://public-yum.oracle.com/docker-images/
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) fmw_12.1.3.0.0_coherence_Disk1_1of1.zip 
#     Download the Standalone installer from http://www.oracle.com/technetwork/middleware/coherence/downloads/index.html
#
# (2) jdk-8u25-linux-x64.rpm
#     Download from http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ sudo sh build.sh
#

# Pull base image
# ---------------
FROM oraclelinux:7

# Maintainer
# ----------
MAINTAINER Bruno Borges <bruno.borges@oracle.com>

# Environment variables required for this build (do NOT change)
ENV JAVA_RPM jdk-8u25-linux-x64.rpm
ENV FMW_PKG  fmw_12.1.3.0.0_coherence_Disk1_1of1.zip
ENV FMW_JAR  fmw_12.1.3.0.0_coherence.jar
ENV FMW_DIR  coherence12130
ENV COHERENCE_HOME /u01/$FMW_DIR/coherence

# Install and configure Oracle JDK 8u25
# -------------------------------------
COPY config/$JAVA_RPM /root/
RUN rpm -i /root/$JAVA_RPM && rm /root/$JAVA_RPM
ENV JAVA_HOME /usr/java/default
ENV CONFIG_JVM_ARGS -Djava.security.egd=file:/dev/./urandom

# Setup required packages (unzip), filesystem, and oracle user
# ------------------------------------------------------------
RUN yum install -y unzip && \ 
    mkdir /u01 && chmod a+xr /u01 && \ 
    useradd -b /u01 -m -s /bin/bash oracle && \
    echo oracle:oracle | chpasswd

# Copy files required to build this image
COPY config/$FMW_PKG /u01/
COPY config/oraInst.loc /u01/oraInst.loc
COPY config/install.file /u01/install.file

WORKDIR /u01
RUN chown oracle:oracle -R /u01
USER oracle

# Installation of Coherence
RUN unzip /u01/$FMW_PKG -d /u01/oracle/ > /dev/null && \
    rm $FMW_PKG && \
    mkdir /u01/oracle/.inventory

WORKDIR /u01/oracle

RUN java -jar $FMW_JAR -silent -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME && \ 
    rm $FMW_JAR && \ 
    ln -s /u01/oracle/$FMW_DIR /u01/oracle/coherence

WORKDIR /u01/oracle/$FMW_DIR

# Cleanup
USER root
RUN rm /u01/oraInst.loc /u01/install.file && \
    yum erase -y unzip && \ 
    yum clean all

VOLUME /u01/oracle/coherence_config

USER oracle

# Define default command to start bash. 
CMD ["bash"]
