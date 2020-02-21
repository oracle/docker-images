#
# Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Description: This file is used to build Oracle WebCenter Sites image
#
# ORACLE DOCKERFILES PROJECT
# -------------------------------------------------------------
# This is the Dockerfile for Oracle WebCenter Sites 12.2.1.3 Generic Distro
# 
# REQUIRED FILES TO BUILD THIS IMAGE
# -------------------------------------------------------------
# (1) V886462-01.zip
#     Download the Oracle WebCenter Sites 12c R2 (12.2.1.3.0) installer from http://www.oracle.com/technetwork/middleware/webcenter/sites/downloads/index.html
#
# HOW TO BUILD THIS IMAGE
# -------------------------------------------------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build -f Dockerfile -t oracle/wcsites:12.2.1.3 . 

# Pull base image from the Oracle Container Registry or Docker Store and tag the name as 'oracle/fmw-infrastructure:12.2.1.3'
# -------------------------------------------------------------
FROM oracle/fmw-infrastructure:12.2.1.3

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
USER root
ENV ORACLE_HOME=/u01/oracle \
	USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
	DOMAIN_NAME="${DOMAIN_NAME:-base_domain}" \
	DOMAIN_ROOT="${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}" \
	DOMAIN_HOME="${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}/${DOMAIN_NAME:-base_domain}" \
	PATH=$PATH:$JAVA_HOME/bin:$ORACLE_HOME/oracle_common/common/bin \
	SITES_CONTAINER_SCRIPTS=/u01/oracle/sites-container-scripts \
	SITES_INSTALLER_PKG=wcs-wls-docker-install \
	SITES_PKG=V886462-01.zip \
	SITES_JAR=fmw_12.2.1.3.0_wcsites.jar \
	ADMIN_PORT=7001 \
	WCSITES_PORT=7002 \
	ADMIN_SSL_PORT=9001 \
	WCSITES_SSL_PORT=9002
	
# Copy packages and scripts 
# -------------------------------------------------------------
COPY sites-container-scripts/* $SITES_CONTAINER_SCRIPTS/
COPY $SITES_INSTALLER_PKG /u01/$SITES_INSTALLER_PKG
COPY $SITES_PKG install.file oraInst.loc /u01/

#Install packages and adjust file permissions, go to /u01 as user 'oracle' to proceed with WLS installation
# -------------------------------------------------------------

RUN yum install -y hostname && \
	rm -rf /var/cache/yum/* && \
	mkdir -p /u01/oracle/logs && \
	chmod a+xr /u01 && \
	chown oracle:oracle -R /u01 && \
	chmod a+xr -R /u01/oracle/*.* && \
	chmod a+xr $SITES_CONTAINER_SCRIPTS/*.*
	
# Install as user
# -------------------------------------------------------------
USER oracle

RUN cd /u01 && \
	$JAVA_HOME/bin/jar xf /u01/$SITES_PKG && \
	cd - && \
	$JAVA_HOME/bin/java -jar /u01/$SITES_JAR -silent -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="WebCenter Sites - With Examples" && \
	rm -rf /u01/fmw_* /u01/oraInst.loc /u01/install.file
	
COPY sites-container-scripts/overrides/oui/* /u01/oracle/wcsites/common/templates/wls/
COPY sites-container-scripts/overrides/installer/* /u01/oracle/wcsites/webcentersites/sites-home/bootstrap/installer/install/
COPY sites-container-scripts/overrides/config/* /u01/oracle/wcsites/webcentersites/sites-home/template/config/
	
RUN cd /u01/oracle/wcsites/common/templates/wls && \
	$JAVA_HOME/bin/jar uvf oracle.wcsites.base.template.jar startup-plan.xml file-definition.xml && \
	rm /u01/oracle/wcsites/common/templates/wls/startup-plan.xml && \
	rm /u01/oracle/wcsites/common/templates/wls/file-definition.xml

# Expose all Ports
# -------------------------------------------------------------
EXPOSE $ADMIN_PORT $ADMIN_SSL_PORT $WCSITES_PORT $WCSITES_SSL_PORT

WORKDIR $ORACLE_HOME

# Define default command to start bash.
# -------------------------------------------------------------
CMD ["/u01/oracle/sites-container-scripts/createSitesDomainandStartAdmin.sh"]