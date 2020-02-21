#
# Copyright (c) 2019, 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Description: This file is used to build Oracle WebCenter Sites image
#
# ORACLE DOCKERFILES PROJECT
# -------------------------------------------------------------
# This is the Dockerfile for Oracle WebCenter Sites 12.2.1.4 Generic Distro
# 
# REQUIRED FILES TO BUILD THIS IMAGE
# -------------------------------------------------------------
# (1) V983400-01.zip
#     Download the Oracle WebCenter Sites 12c R2 (12.2.1.4.0) installer from https://www.oracle.com/middleware/technologies/webcenter-sites/downloads.html
#
# HOW TO BUILD THIS IMAGE
# -------------------------------------------------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build -f Dockerfile -t oracle/wcsites:12.2.1.4 . 

# Pull base image from the Oracle Container Registry or Docker Store and tag the name as 'oracle/fmw-infrastructure:12.2.1.4'
# -------------------------------------------------------------
FROM oracle/fmw-infrastructure:12.2.1.4 as builder

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
USER root
ENV SITES_CONTAINER_SCRIPTS=/u01/oracle/sites-container-scripts \
	SITES_INSTALLER_PKG=wcs-wls-docker-install \
	SITES_PKG=V983400-01.zip \
	SITES_JAR=fmw_12.2.1.4.0_wcsites.jar
	
# Copy packages and scripts 
# -------------------------------------------------------------
COPY sites-container-scripts/* $SITES_CONTAINER_SCRIPTS/
COPY $SITES_INSTALLER_PKG /u01/$SITES_INSTALLER_PKG
COPY $SITES_PKG install.file oraInst.loc /u01/

#Install packages and adjust file permissions, go to /u01 as user 'oracle' to proceed with WLS installation
# -------------------------------------------------------------

RUN mkdir -p /u01/oracle/logs && \
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
	rm -rf /u01/$SITES_PKG /u01/$SITES_JAR /u01/oraInst.loc /u01/install.file
	
COPY sites-container-scripts/overrides/oui/* /u01/oracle/wcsites/common/templates/wls/
COPY sites-container-scripts/overrides/installer/* /u01/oracle/wcsites/webcentersites/sites-home/bootstrap/installer/install/
COPY sites-container-scripts/overrides/config/* /u01/oracle/wcsites/webcentersites/sites-home/template/config/
	
RUN cd /u01/oracle/wcsites/common/templates/wls && \
	$JAVA_HOME/bin/jar uvf oracle.wcsites.base.template.jar startup-plan.xml file-definition.xml && \
	rm /u01/oracle/wcsites/common/templates/wls/startup-plan.xml && \
	rm /u01/oracle/wcsites/common/templates/wls/file-definition.xml
	
#
# Rebuild from base image
# -----------------------
FROM oracle/fmw-infrastructure:12.2.1.4

#
# Install the required packages
# -----------------------------
USER root
ENV SITES_CONTAINER_SCRIPTS=/u01/oracle/sites-container-scripts \
	SITES_INSTALLER_PKG=wcs-wls-docker-install \
	DOMAIN_ROOT="${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}" \
	ADMIN_PORT=7001 \
	WCSITES_PORT=7002 \
	ADMIN_SSL_PORT=9001 \
	WCSITES_SSL_PORT=9002 \
    PATH=$PATH:/u01/oracle/sites-container-scripts
	
RUN yum install -y hostname && \
    rm -rf /var/cache/yum
	
COPY --from=builder --chown=oracle:oracle /u01 /u01

# Expose all Ports
# -------------------------------------------------------------
EXPOSE $ADMIN_PORT $ADMIN_SSL_PORT $WCSITES_PORT $WCSITES_SSL_PORT

USER oracle
WORKDIR $ORACLE_HOME
# Define default command to start.
# -------------------------------------------------------------
CMD ["/u01/oracle/sites-container-scripts/createOrStartSitesDomain.sh"]
