# Example of Apache HTTP Server with WebLogic plugin for load balancing WebLogic on Docker Containers
#
# Copyright (c) 2016-2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# For version 12.2.1.3 Required file fmw_12.2.1.3.0_wlsplugins_Disk1_1of1.zip
# For Version 12.2.1.4 Required file fmw_12.2.1.4.0_wlsplugins_Disk1_1of1.zip
# Download the generic installer from http://www.oracle.com/technetwork/middleware/webtier/downloads/index-jsp-156711.html and save it in this same folder.
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# RUN:
#      $ sh buildDockerImage.sh -v <version>
#  The value of version is either 12.2.1.3.0 or 12.2.1.4.0   
#
# PULL BASE IMAGE
# -----------------------------------
FROM oraclelinux:7-slim
#Defined ARG Variable VERSION to pass through the value to the environment variables
ARG VERSION=12.2.1.3.0

# Environment variables required for this build (do NOT change)
# ----------------------------------------------
ENV FMW_PKG="fmw_${VERSION}_wlsplugins_Disk1_1of1.zip" \
    PLUGINS_PKG="WLSPlugins12c-${VERSION}.zip" \
    PLUGIN_PKG="WLSPlugin${VERSION}-Apache2.2-Apache2.4-Linux_x86_64-${VERSION}.zip" \
    PLUGIN_HOME="/u01/oracle" \
    MOD_WLS_PLUGIN="mod_wl_24.so" \
    LD_LIBRARY_PATH="/u01/oracle/lib" \
    WEBLOGIC_CLUSTER="server0:7002,server1:7002" \
    LOCATION="/weblogic" \
    WEBLOGIC_HOST="wlsadmin" \
    WEBLOGIC_PORT="7001" \
    NonPriviledgedPorts="false" \
    VERSION="$VERSION"

# Copy required files to build this image
# ------------------------------------------------------
COPY $FMW_PKG /tmp/
COPY weblogic.conf /etc/httpd/conf.d/ 
COPY pluginWeblogic.conf /etc/ld.so.conf.d/
COPY custom_mod_wl_apache.conf.sample /config/custom_mod_wl_apache.conf
COPY custom_mod_wl_apache.conf.sample /configtmp/custom_mod_wl_apache.conf
COPY custom_mod_ssl_apache.conf.sample /configtmp/custom_mod_ssl_apache.conf
COPY custom_mod_mpm.conf.sample /etc/httpd/conf.modules.d/00-mpm.conf
COPY custom_mod_cgi.conf.sample /etc/httpd/conf.modules.d/01-cgi.conf
COPY container-scripts/* /u01/oracle/container-scripts/


# Use unzip because the base image does not contain a JDK
# Note that adding unzip does not noticeably increase the size of the image
RUN yum install -y sudo unzip httpd libaio mod_ssl.x86_64 && \
    groupadd sudo && \					 
    useradd -b /u01 -d /u01/oracle -m -G sudo -s /bin/bash oracle && \
    touch /etc/sudoers.d/oracle && \
    visudo -c -q -f /etc/sudoers.d/oracle && \
    chmod 600 /etc/sudoers.d/oracle && \
    sed -i /etc/sudoers.d/oracle -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' && \
    sed -i /etc/sudoers.d/oracle -re 's/^root.*/root ALL=(ALL:ALL) NOPASSWD: ALL/g' && \
    echo "oracle ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/oracle && \
    unzip /tmp/$FMW_PKG -d /tmp && \
    unzip /tmp/$PLUGINS_PKG -d /tmp && \
    unzip /tmp/$PLUGIN_PKG -d $PLUGIN_HOME && \
    sed -i -e "s;logs/error_log;/proc/self/fd/2;" /etc/httpd/conf/httpd.conf && \
    sed -i -e "s;logs/access_log;/proc/self/fd/1;" /etc/httpd/conf/httpd.conf && \
    sed -i -e "s;User apache;User oracle;" /etc/httpd/conf/httpd.conf && \
    sed -i -e "s;Group apache;Group oracle;" /etc/httpd/conf/httpd.conf && \
    sed -i -e "s;root apache;oracle oracle;" /usr/lib/tmpfiles.d/httpd.conf && \
    sed -i -e "s;apache apache;oracle oracle;" /usr/lib/tmpfiles.d/httpd.conf && \
    chown -R oracle /var/log/httpd && \
    chown oracle  -R /etc/httpd/logs/ && \
    chown oracle -R /etc/pki/tls/certs/localhost.crt && \
    chown oracle -R /etc/pki/tls/private/localhost.key && \
    setcap cap_net_bind_service=+epi /usr/sbin/httpd && \
    ldconfig && \
    rm /tmp/$PLUGINS_PKG /tmp/WLSPlugin${VERSION}-*.zip /tmp/$FMW_PKG /tmp/fmw_12*_readme* && \
    chown oracle:oracle -R /u01 && \
    chown oracle:oracle -R /tmp && \
    chown oracle:oracle -R /config && \
    chown oracle:oracle -R /run

#Expose ports
EXPOSE 80 4433

USER oracle 

# Provision Apache instance
CMD ["/u01/oracle/container-scripts/run-httpd.sh"]
