# LICENSE GNU 3.0
#
# Copyright (c) 2017 CERN.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic image by creating a sample domain and deploying the CGIServlet.
# See: https://docs.oracle.com/middleware/1213/wls/WBAPP/configureresources.htm#WBAPP220
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Run: #
#      $ docker build -t 1213-domain --build-arg ADMIN_PASSWORD=welcome1 --build-arg CGI_DIR_VALUE=/u01/oracle/cgi-scripts build-arg CGI_EXTENSION_MAPPING=*.sh --build-arg CGI_INTERPRETER=/bin/sh --build-arg CGI_APP_NAME=cgi-app --build-arg CGI_SERVLET_URL_PATTERN=/cgi-bin/* .

# Pull base image
# ---------------
FROM oracle/weblogic:12.1.3-developer

# Maintainer
# ----------
MAINTAINER Luis Rodriguez Fernandez <luis.rodriguez.fernandez@cern.ch>

# WLS Configuration
# -------------------------------
ARG ADMIN_PASSWORD
ARG CGI_DIR_VALUE
ARG CGI_EXTENSION_MAPPING
ARG CGI_INTERPRETER
ARG CGI_APP_NAME
ARG CGI_SERVLET_URL_PATTERN

ENV DOMAIN_NAME="base_domain" \
    DOMAIN_HOME="/u01/oracle/user_projects/domains/base_domain" \
    ADMIN_PORT="7001" \
    ADMIN_HOST="wlsadmin" \
    PRODUCTION_MODE="dev" \
    CGI_DIR_VALUE="${CGI_DIR_VALUE:-/u01/oracle/cgi-scripts}" \
    CGI_EXTENSION_MAPPING="${CGI_EXTENSION_MAPPING:-*.sh}" \
    CGI_INTERPRETER="${CGI_INTERPRETER:-/bin/sh}" \
    CGI_APP_NAME="${CGI_APP_NAME:-cgi-app}" \
    CGI_SERVLET_URL_PATTERN="${CGI_SERVLET_URL_PATTERN:-/cgi-bin/*}" \
    PATH=$PATH:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/user_projects/domains/base_domain/bin:/u01/oracle

# Add files required to build this image
USER oracle
COPY container-scripts/* /u01/oracle/

# Configuration of WLS Domain
WORKDIR /u01/oracle
RUN /u01/oracle/wlst /u01/oracle/create-wls-domain.py && \
    mkdir -p /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/security && \
    echo "username=weblogic" > /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/security/boot.properties && \ 
    echo "password=$ADMIN_PASSWORD" >> /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/security/boot.properties && \
    echo ". /u01/oracle/user_projects/domains/base_domain/bin/setDomainEnv.sh" >> /u01/oracle/.bashrc && \ 
    echo "export PATH=$PATH:/u01/oracle/wlserver/common/bin:/u01/oracle/user_projects/domains/base_domain/bin" >> /u01/oracle/.bashrc

# Expose the AdminServer port
EXPOSE $ADMIN_PORT

# Creation of the CGIServlet application
#---------------------------------------
# Create the application context folder
ENV CGI_APP_HOME="/u01/oracle/"$CGI_APP_NAME

RUN mkdir $CGI_APP_HOME
# Create the WEB-INF folder
RUN mkdir $CGI_APP_HOME/WEB-INF
# Add the web.xml descriptor to the WEB-INF folder
ADD web.xml $CGI_APP_HOME/WEB-INF
# Set the values in the web.xml
RUN sed -i -e "s|CGI_DIR_VALUE|$CGI_DIR_VALUE|g" $CGI_APP_HOME/WEB-INF/web.xml && \
  sed -i -e "s|CGI_EXTENSION_MAPPING|$CGI_EXTENSION_MAPPING|g" $CGI_APP_HOME/WEB-INF/web.xml && \
  sed -i -e "s|CGI_INTERPRETER|$CGI_INTERPRETER|g" $CGI_APP_HOME/WEB-INF/web.xml && \
  sed -i -e "s|CGI_SERVLET_URL_PATTERN|$CGI_SERVLET_URL_PATTERN|g" $CGI_APP_HOME/WEB-INF/web.xml

# Change the working directory
WORKDIR $CGI_APP_HOME
# Create the .war file
RUN jar -cvf $CGI_APP_NAME.war *

# Add the scripts to be executed by the CGIServlet
#-------------------------------------------------
# Create the dir
RUN mkdir $CGI_DIR_VALUE
# Add the scripts
ADD cgi-scripts/* $CGI_DIR_VALUE/
# Give them permissions to be executed
USER root
RUN chmod ug+x $CGI_DIR_VALUE/* && \
    chmod 0755 /u01/oracle/wlserver/server/native/linux/x86_64/libwlenv.so && \
    chown -R oracle:oracle $CGI_DIR_VALUE

# Deploy the CGI_Servlet application
#-----------------------------------
# Use autodeploy feature of WLS AdminServer
RUN mv $CGI_APP_HOME/$CGI_APP_NAME.war $DOMAIN_HOME/autodeploy

# Install the libstdc++.x86_64 library
#-------------------------------------
RUN yum install -y \
    compat-libstdc++-33-3.2.3-71.el7.x86_64 && \
    yum install -y perl && \
    yum clean all && rm -rf /var/cache/yum/*

# Finalize the setup
#------------------
# Set the working directory to $DOMAIN_HOME
WORKDIR $DOMAIN_HOME
# Back to oracle user
USER oracle

# Define default command to start bash. 
CMD ["startWebLogic.sh"]
