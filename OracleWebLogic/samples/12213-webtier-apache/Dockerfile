# Example of Apache HTTP Server with WebLogic plugin for load balancing WebLogic on Docker Containers
#
# Copyright (c) 2016-2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# fmw_12.2.1.3.0_wlsplugins_Disk1_1of1.zip
# Download the generic installer from http://www.oracle.com/technetwork/middleware/webtier/downloads/index-jsp-156711.html and save it in this same folder.
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# RUN:
#      $ sh buildDockerImage.sh
#
# PULL BASE IMAGE
# -----------------------------------
FROM oraclelinux:7-slim

# Environment variables required for this build (do NOT change)
# ----------------------------------------------
ENV FMW_PKG="fmw_12.2.1.3.0_wlsplugins_Disk1_1of1.zip" \
    PLUGINS_PKG="WLSPlugins12c-12.2.1.3.0.zip" \
    PLUGIN_PKG="WLSPlugin12.2.1.3.0-Apache2.2-Apache2.4-Linux_x86_64-12.2.1.3.0.zip" \
    PLUGIN_HOME="/u01/oracle" \
    MOD_WLS_PLUGIN="mod_wl_24.so" \
    LD_LIBRARY_PATH="/u01/oracle/lib" \
    WEBLOGIC_CLUSTER="server0:7002,server1:7002" \
    LOCATION="/weblogic" \
    WEBLOGIC_HOST="wlsadmin" \
    WEBLOGIC_PORT="7001" 


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
RUN yum install -y sudo unzip httpd libaio mod_ssl.x86_64

RUN groupadd sudo && \
    useradd -b /u01 -d /u01/oracle -m -G sudo -s /bin/bash oracle && \
    touch /etc/sudoers && \
    sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' && \
    sed -i /etc/sudoers -re 's/^root.*/root ALL=(ALL:ALL) NOPASSWD: ALL/g' && \
    sed -i /etc/sudoers -re 's/^#includedir.*/## **Removed the include directive** ##"/g' && \
    echo "oracle ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    unzip /tmp/$FMW_PKG -d /tmp && \
    unzip /tmp/$PLUGINS_PKG -d /tmp && \
    unzip /tmp/$PLUGIN_PKG -d $PLUGIN_HOME && \
    sed -i -e "s;logs/error_log;/proc/self/fd/2;" /etc/httpd/conf/httpd.conf && \
    sed -i -e "s;logs/access_log;/proc/self/fd/1;" /etc/httpd/conf/httpd.conf && \
    sed -i -e "s;User apache;User oracle;" /etc/httpd/conf/httpd.conf && \
    sed -i -e "s;Group apache;Group oracle;" /etc/httpd/conf/httpd.conf && \
    sed -i -e "s;Listen 80;Listen 8080;" /etc/httpd/conf/httpd.conf  && \
    sed -i -e "s;root apache;oracle oracle;" /usr/lib/tmpfiles.d/httpd.conf && \
    sed -i -e "s;apache apache;oracle oracle;" /usr/lib/tmpfiles.d/httpd.conf && \
    chown -R oracle /var/log/httpd && \
    chown oracle  -R /etc/httpd/logs/ && \
    chown oracle -R /etc/pki/tls/certs/localhost.crt && \
    chown oracle -R /etc/pki/tls/private/localhost.key && \
    setcap cap_net_bind_service=+epi /usr/sbin/httpd && \
    ldconfig && \
    rm /tmp/$PLUGINS_PKG /tmp/WLSPlugin12.2.1.3.0-*.zip /tmp/$FMW_PKG /tmp/fmw_12213_readme* && \
    chown oracle:oracle -R /u01 && \
    chown oracle:oracle -R /tmp && \
    chown oracle:oracle -R /config && \
    chown oracle:oracle -R /run

#Expose ports
EXPOSE 8080 4433

USER oracle 

# Provision Apache instance
CMD ["/u01/oracle/container-scripts/run-httpd.sh"]
