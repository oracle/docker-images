#
# Dockerfile template for Tuxedo 12.1.3
# 
# Download the following files to an empty directory:
#   tuxedo121300_64_Linux_01_x86.zip	from http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html
#   p22090512_121300_Linux-x86-64.zip 	or whatever the latest Tuxedo rolling patch is from My Oracle Support
#

# Pull base image
FROM oraclelinux

MAINTAINER Todd Little <todd.little@oracle.com>

# Core install doesn't include unzip or gcc, add them
# Create the installation directory tree and user oracle with a password of oracle
RUN yum -y install unzip gcc file; yum -y clean all && \
    groupadd -g 1000 oracle; useradd -b /home -m -g oracle -u 1000 -s /bin/bash oracle && \
    echo oracle:oracle | chpasswd; echo root:samplesvm | chpasswd

COPY install.sh tuxedo12.1.3.rsp p*_121300_Linux-x86-64.zip tuxedo121300_64_Linux_01_x86.zip /home/oracle/Downloads/
#ADD simpapp_runme.sh start_tlisten.sh /home/oracle/

RUN chown oracle:oracle -R /home/oracle
WORKDIR /home/oracle/Downloads
USER oracle

# Install Tuxedo, SALT, and TSAM Agent
RUN sh tuxedo12.1.3_silent_install.sh p*_121300_Linux-x86-64.zip tuxedo121300_64_Linux_01_x86.zip
ENV TUXDIR /home/oracle/tuxHome/tuxedo12.1.3.0.0

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




