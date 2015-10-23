# LICENSE CDDL 1.0 + GPL 2.0
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for WebLogic 12.2.1 Quick Install Distro
# 
# IMPORTANT
# ---------
# The resulting image of this Dockerfile DOES NOT contain a WLS Domain.
# For that, look into the folder 'samples' for an example on how
# to create a domain on a new inherited image.
#
# You can go into 'samples/12.2.1-generic-domain' after building the generic raw image
# and build that image, for example:
# 
#   $ cd samples/12c-generic-domain
#   $ sudo docker build -t mywls .
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) fmw_12.2.1.0.0_wls_supplemental_quick.jar
#     Download the Developer Quick installer from http://www.oracle.com/technetwork/middleware/weblogic/downloads/wls-for-dev-1703574.html 
#
# (2) jdk-8u60-linux-x64.rpm
#     Download from http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ sudo docker build -t oracle/weblogic:12.2.1 . 
#
# Pull base image
# ---------------
FROM oracle/weblogic:12.2.1-dev

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# Environment variables required for this build (do NOT change)
#ENV WLS_PKG wls_supplemental_quick1221_generic.jar
ENV WLS_PKG fmw_12.2.1.0.0_wls_supplemental_quick.jar 
ENV JAVA_HOME /usr/java/default
ENV ORACLE_HOME /u01/oracle/weblogic
ENV CONFIG_JVM_ARGS -Djava.security.egd=file:/dev/./urandom
ENV USER_MEM_ARGS -Xms256m -Xmx512m -XX:MaxPermSize=2048m
ENV JAVA_OPTIONS -XX:+PrintCommandLineFlags



# Setup filesystem and oracle user
# ------------------------------------------------------------

WORKDIR /u01
# Copy packages
COPY $WLS_PKG /u01/



# Installation of Supplemental Quick Installer 
USER oracle
WORKDIR /u01
RUN java -jar $WLS_PKG ORACLE_HOME=$ORACLE_HOME && \
    rm /u01/$WLS_PKG

# Add files required to build this image
COPY container-scripts/* /u01/oracle/

# Set environment to create a Medrec domain and start a single server with a deployed medrec application
RUN echo "cp /u01/oracle/weblogic.properties /u01/oracle/weblogic/wlserver/samples/server/medrec/weblogic.properties" >> /u01/oracle/.bashrc && \
    echo "cp /u01/oracle/startSamples.sh /u01/oracle/weblogic/wlserver/samples/server/medrec/startSamples.sh" >> /u01/oracle/.bashrc && \
    echo ". /u01/oracle/weblogic/wlserver/samples/server/medrec/startSamples.sh" >> /u01/oracle/.bashrc

WORKDIR /u01/oracle/weblogic/wlserver/samples/server/medrec

ENV PATH $PATH:/u01/oracle/weblogic/wlserver/common/bin:/u01/oracle/weblogic/user_projects/domains/medrec/bin:/u01/oracle

# Define default command to start bash. 
CMD ["bash"]
