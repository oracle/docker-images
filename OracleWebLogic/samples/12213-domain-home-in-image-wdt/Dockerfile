#Copyright (c) 2018, 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic image by creating a sample domain.
#
# Util scripts are copied into the image enabling users to plug NodeManager
# automatically into the AdminServer running on another container.
#
# PREREQUISITES:
# --------------
# This sample requires that a Java JDK 1.8 or greater version must be installed on the machine
# running the docker build command, and that the JAVA_HOME environment variable is set to the java home
# location. The sample unzips the weblogic-deploy.zip into the image using the java jar command.
#
# HOW TO BUILD THIS IMAGE
# -----------------------

# Build the deployment archive file using the build-archive.sh script.
#      $ ./build-archive.sh
#
# Run:
#      $ sudo docker build \
#            --build-arg CUSTOM_ADMIN_HOST=wlsadmin \
#            --build-arg CUSTOM_ADMIN_PORT=7001 \
#            --build-arg CUSTOM_ADMIN_NAME=7001 \
#            --build-arg CUSTOM_MANAGED_SERVER_PORT=8001 \
#            --build-arg CUSTOM_DOMAIN_NAME=base_domain \
#            --build-arg CUSTOM_DEBUG_PORT=8453 \
#            --build-arg WDT_MODEL=simple-topology.yaml \
#            --build-arg WDT_ARCHIVE=archive.zip \
#            --build-arg WDT_VARIABLE=properties/docker-build/domain.properties \
#            --force-rm=true \
#            --no-cache=true \
#            -t 12213-domain-home-in-image-wdt .
#
# If the ADMIN_HOST, ADMIN_PORT, MS_PORT, DOMAIN_NAME are not provided, the variables 
# are set to default values. (The values shown in the build statement). 
#
# You must insure that the build arguments align with the values in the model. 
# The sample model replaces the attributes with tokens that are resolved from values in the
# corresponding property file domain.properties. The container-scripts/setEnv.sh script
# demonstrates parsing the variable file to build a string of --build-args that can
# be passed on the docker build command.
#
# Pull base image
# ---------------
FROM oracle/weblogic:12.2.1.3

# Maintainer
# ----------
MAINTAINER Richard Killen <richard.killen@oracle.com>

ARG WDT_ARCHIVE
ARG WDT_VARIABLE
ARG WDT_MODEL
ARG CUSTOM_ADMIN_NAME=admin-server
ARG CUSTOM_ADMIN_HOST=wlsadmin
ARG CUSTOM_ADMIN_PORT=7001
ARG CUSTOM_MANAGED_SERVER_PORT=8001
ARG CUSTOM_DOMAIN_NAME=base_domain
ARG CUSTOM_DEBUG_PORT=8453

# Persist arguments - for ports to expose and container to use
# Create a placeholder for the manager server name. This will be provided when run the container
# Weblogic and Domain locations
# The boot.properties will be created under the DOMAIN_HOME when the admin server container is run 
# WDT installation
# ---------------------------
ENV ADMIN_NAME=${CUSTOM_ADMIN_NAME} \
    ADMIN_HOST=${CUSTOM_ADMIN_HOST} \
    ADMIN_PORT=${CUSTOM_ADMIN_PORT} \
    MANAGED_SERVER_NAME=${MANAGED_SERVER_NAME} \
    MANAGED_SERVER_PORT=${CUSTOM_MANAGED_SERVER_PORT} \
    DEBUG_PORT=${CUSTOM_DEBUG_PORT} \
    ORACLE_HOME=/u01/oracle \
    DOMAIN_NAME=${CUSTOM_DOMAIN_NAME} \
    DOMAIN_PARENT=${ORACLE_HOME}/user_projects/domains 

ENV DOMAIN_HOME=${DOMAIN_PARENT}/${DOMAIN_NAME} \
    PROPERTIES_FILE_DIR=$ORACLE_HOME/properties \
    WDT_HOME="/u01" \
    SCRIPT_HOME="${ORACLE_HOME}" \
    PATH=$PATH:${ORACLE_HOME}/oracle_common/common/bin:${ORACLE_HOME}/wlserver/common/bin:${DOMAIN_HOME}:${DOMAIN_HOME}/bin:${ORACLE_HOME}

COPY weblogic-deploy.zip ${WDT_HOME}
COPY container-scripts/* ${SCRIPT_HOME}/

# Create the properties file directory and the domain home parent with the correct permissions / owner. 
# Unzip and install the WDT image and change the permissions / owner.
USER root
RUN chmod +xw ${SCRIPT_HOME}/*.sh && \ 
    chown -R oracle:root ${SCRIPT_HOME} && \
    mkdir -p +xwr $PROPERTIES_FILE_DIR && \
    chown -R oracle:root $PROPERTIES_FILE_DIR && \
    mkdir -p $DOMAIN_PARENT && \
    chown -R oracle:root $DOMAIN_PARENT && \
    chmod -R 770 $DOMAIN_PARENT && \
    cd ${WDT_HOME} && \
    $JAVA_HOME/bin/jar xf weblogic-deploy.zip && \
    rm weblogic-deploy.zip && \
    chmod +xw weblogic-deploy/bin/*.sh && \
    chmod -R g+w weblogic-deploy/lib && \
    chown -R oracle:root weblogic-deploy 

# Persist the WDT tool home location
ENV WDT_HOME=$WDT_HOME/weblogic-deploy 

# Copy the WDT model, archive file, variable file and credential secrets to the property file directory.
# These files will be removed after the image is built.
# Be sure to build with --force-rm to eliminate this container layer

COPY ${WDT_MODEL} ${WDT_ARCHIVE} ${WDT_VARIABLE} properties/docker-build/*.properties ${PROPERTIES_FILE_DIR}/
# --chown for COPY is available in docker version 18 'COPY --chown oracle:root'
RUN chown -R oracle:root ${PROPERTIES_FILE_DIR}
         
# Create the domain home in the docker image.
#
# The create domain tool creates a domain at the DOMAIN_HOME location
# The domain name is set using the value in the model / variable files 
# The domain name can be different from the DOMAIN_HOME domain folder name.
#
# Set WORKDIR for @@PWD@@ global token in model file
WORKDIR $ORACLE_HOME
USER oracle
RUN if [ -n "$WDT_MODEL" ]; then MODEL_OPT="-model_file $PROPERTIES_FILE_DIR/${WDT_MODEL##*/}"; fi && \
    if [ -n "$WDT_ARCHIVE" ]; then ARCHIVE_OPT="-archive_file $PROPERTIES_FILE_DIR/${WDT_ARCHIVE##*/}"; fi && \
    if [ -n "$WDT_VARIABLE" ]; then VARIABLE_OPT="-variable_file $PROPERTIES_FILE_DIR/${WDT_VARIABLE##*/}"; fi && \ 
    ${WDT_HOME}/bin/createDomain.sh \
        -oracle_home $ORACLE_HOME \
        -java_home $JAVA_HOME \
        -domain_home $DOMAIN_HOME \
        -domain_type WLS \
        $VARIABLE_OPT  \
        $MODEL_OPT \
        $ARCHIVE_OPT && \
        chmod -R g+w $DOMAIN_HOME && \ 
        echo ". $DOMAIN_HOME/bin/setDomainEnv.sh" >> /u01/oracle/.bashrc && \
        rm -rf $PROPERTIES_FILE_DIR 

# Expose admin server, managed server port and domain debug port
EXPOSE $ADMIN_PORT $MANAGED_SERVER_PORT $DEBUG_PORT

WORKDIR $DOMAIN_HOME

# Define default command to start Admin Server in a container.
CMD ["/u01/oracle/startAdminServer.sh"]
