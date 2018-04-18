# Example of Apache Web Server with WebLogic plugin for load balancing WebLogic on Docker Containers
#
# Copyright (c) 2016-2018 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# fmw_12.2.1.3.0_wls_Disk1_1of1.zip 
# Download the Generic installer from http://www.oracle.com/technetwork/middleware/weblogic/downloads/wls-for-dev-1703574.html and save it in this same folder.
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build -t 12213-apache . 
# or
# RUN:
#      $ sh build.sh
#
# For Oracle developers, use build_internal.sh, which set up HTTP/HTTPS proxies.
# RUN:
#      $ sh build_internal.sh
#
# Note if needed, pull the latest httpd image and tag it as: httpd:2.4
#
FROM httpd:2.4

ENV FMW_PKG="fmw_12.2.1.3.0_wlsplugins_Disk1_1of1.zip" \
    PLUGINS_PKG="WLSPlugins12c-12.2.1.3.0.zip" \
    PLUGIN_PKG="WLSPlugin12.2.1.3.0-Apache2.2-Apache2.4-Linux_x86_64-12.2.1.3.0.zip" \
    PLUGIN_HOME="/root" \
    MOD_WLS_PLUGIN="mod_wl_24.so" \
    LD_LIBRARY_PATH="/root/lib" \
    WEBLOGIC_CLUSTER="server0:7002,server1:7002" \
    LOCATION="/weblogic" \
    WEBLOGIC_HOST="wlsadmin" \
    WEBLOGIC_PORT="7001" 

COPY $FMW_PKG weblogic.conf /tmp/
COPY custom_mod_wl_apache.conf.sample /config/custom_mod_wl_apache.conf

RUN apt-get update && apt-get install -y unzip && \
    unzip /tmp/$FMW_PKG -d /tmp && \
    unzip /tmp/$PLUGINS_PKG -d /tmp && \
    unzip /tmp/$PLUGIN_PKG -d $PLUGIN_HOME && \
    cat /tmp/weblogic.conf >> /usr/local/apache2/conf/httpd.conf  && \
    rm /tmp/$PLUGINS_PKG /tmp/WLSPlugin12.2.1.3.0-*.zip /tmp/$FMW_PKG /tmp/weblogic.conf
