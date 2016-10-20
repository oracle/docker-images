# Dockerfile template for Tuxedo 12.2.2
# 
# Download the following files to an empty directory:
#   tuxedo122200_64_Linux_01_x86.zip	from http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html
#
# For Tuxedo 12.2.2, you need JRE installed first, so before you can build this image, you must download the Oracle Server JRE binary and drop in folder OracleJava/java-8 and build that image.
#
#   cd ../OracleJava/java-8
#   sh build.sh

# Pull base image
FROM oracle/serverjre:8

MAINTAINER Todd Little <todd.little@oracle.com>

# Core install doesn't include unzip or gcc, add them
# Create the installation directory tree and user oracle with a password of oracle
RUN yum -y install unzip gcc file; yum -y clean all && \
    groupadd -g 1000 oracle; useradd -b /home -m -g oracle -u 1000 -s /bin/bash oracle && \
    echo oracle:oracle | chpasswd; echo root:samplesvm | chpasswd

COPY install.sh tuxedo12.2.2.rsp tuxedo122200_64_Linux_01_x86.zip /home/oracle/Downloads/
RUN chown oracle:oracle -R /home/oracle
WORKDIR /home/oracle/Downloads
USER oracle
# Install Tuxedo, SALT, and TSAM Agent
RUN sh install.sh tuxedo122200_64_Linux_01_x86.zip
ENV TUXDIR /home/oracle/tuxHome/tuxedo12.2.2.0.0

# Clean up installer files
RUN rm -f *.zip
#
# Configure network ports
# tlisten	nlsaddr:5001  jmx:5002
# SALT 		http:5010
# WSL		5020
#EXPOSE 5001 5002 5010 5020
#USER root
#RUN yum -y install bind-utils

USER oracle
WORKDIR /home/oracle




