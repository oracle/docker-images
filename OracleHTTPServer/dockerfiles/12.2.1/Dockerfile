# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE HTTP Server DOCKERFILES PROJECT
# -----------------------------------------
# This is the DockerFile for Oracle HTTP Server 12.2.1
#
# IMPORTANT
# -------------------------------------------
# The resulting image of this Dockerfile would have Oracle Linux 7 and Oracle HTTP Server 1221 installed in standalone mode.
# No domain will be configured in this image
#
# For Creating a OHSdomain out of above image
# You can go into 'samples/1221-OHS-domain' and build image using DockerFile provided in it
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) fmw_12.2.1.0.0_ohs_linux64_Disk1_1of1.zip
#     Download from http://www.oracle.com/technetwork/middleware/webtier/downloads/index-jsp-156711.html
#
# (2) server-jre-8uXX-linux-x64.tar.gz
#     Download from http://www.oracle.com/technetwork/java/javase/downloads/server-jre8-downloads-2133154.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# As root user run following command manually:
#
#     $ sh buildDockerImage.sh -v 12.2.1
#
# Alternatively you can also run
# 
#     $ docker build --force-rm=true --no-cache=true --rm=true -t oracle/$IMAGE_NAME:$VERSION-$INSTALL_TYPE .
#
# For example
# 
#     $ docker build --force-rm=true --no-cache=true --rm=true -t oracle/ohs:12.2.1-sa .
#
# Pull Oracle Linux 7 base image
# -----------------------------------
FROM oraclelinux:latest

# Maintainer
# ------------------------------------
MAINTAINER Hemastuti Baruah <hemastuti.baruah@oracle.com>

# Environment variables required for this build (do NOT change)
# ----------------------------------------------
ENV JAVA_PKG=server-jre-8u*-linux-x64.tar.gz \
    OHS_PKG=fmw_12.2.1.0.0_ohs_linux64_Disk1_1of1.zip \
    OHS_BIN=fmw_12.2.1.0.0_ohs_linux64.bin \
    JAVA_HOME=/usr/java/default \
    ORACLE_HOME=/u01/oracle/ohssa \
    PATH=$PATH:$JAVA_HOME/bin:$ORACLE_HOME/oracle_common/common/bin

# Copy packages to the new drive
# -------------------------------------------------------
COPY $OHS_PKG install.file oraInst.loc /u01/
ADD $JAVA_PKG /usr/java/

# Install OL7 required packages. Refer FMW 12.2.1 System requirements guide for complete list of packages
# Change the open file limits and kernel parameters that need changing
# Setup filesystem and oracle user
#---------------------------------------------------------------------------------------------------------
# Proxy needs to be set before running yum in /etc/yum.conf
RUN yum install -y \
        unzip tar nfs-utils binutils compat-libcap1 compat-libstdc++ \
        gcc gcc-c++ glibc glibc-devel libaio libaio-devel libgcc \
	libstdc++ libstdc++-devel ksh make ocfs2-tools sysstat && \
    chmod a+xr /u01 && \
    useradd -b /u01 -m -s /bin/bash oracle && \
    echo oracle:oracle | chpasswd && \
    mkdir /u01/oracle/.inventory

# Install and configure Oracle JDK
# Go to /u01 as user 'oracle' to proceed with OHS installation
#--------------------------------------------------------
RUN ln -s $(ls -1 /usr/java) $JAVA_HOME && \
    cd /u01 && unzip -q /u01/$OHS_PKG && cd - && \
    chown oracle:oracle -R /u01 && cd - && \
    su -c "/u01/$OHS_BIN -ignoreSysPrereqs -novalidation -silent -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME ORACLE_HOME=$ORACLE_HOME" - oracle && \
    rm $FMW_JAR $FMW_PKG oraInst.loc install.file

USER oracle
WORKDIR /u01/oracle/

# Define default command to start bash.
CMD ["bash"]
