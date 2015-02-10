# LICENSE CDDL 1.0 + GPL 2.0
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for WebLogic 10.3.6 (Full) Generic Distribution.
#
# IMPORTANT
# ---------
# The resulting image of this Dockerfile DOES NOT contain a WLS Domain.
# For that, look into the folder 'container-domain' for an example on how
# to create a domain on a new inherited image.
#
# You can go into 'sample-with-domain' after building the generic raw image
# and build that image, for example:
# 
#   $ cd sample-with-domain
#   $ sudo docker build -t mywls .
#
# Then you can use dockWebLogic.sh and dockNodeManager with parameter [-i]
# and provide your custom image name. If you customized entirely your
# domain, the dock*.sh scripts may not work due to specific paths.
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) wls1036_linux32.bin
# Download the Generic installer from http://www.oracle.com/technetwork/middleware/weblogic/downloads/wls-main-097127.html
# Extract file wls1036_generic.jar from inside wls1036_linux32.bin. You can use unzip.
#
# (2) jdk-7u75-linux-x64.rpm
# Download from http://www.oracle.com/technetwork/java/javase/downloads/index.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#       $ sudo docker build -t oracle/weblogic:10.3.6 .
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
# For usage, provide argument '-h' for any of three scripts (dock*, and build)#
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
