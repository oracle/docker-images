# Example of Apache Web Server with WebLogic plugin for load balancing WebLogic on Docker Containers
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
# 
# Author: Bruno Borges <bruno.borges@oracle.com>
#
FROM httpd:2.4

ENV PLUGIN_PKG="WLSPlugin12.2.1-Apache2.2-Apache2.4-Linux_x86_64-12.2.1.0.0.zip" \
    PLUGIN_HOME="/root" \
    MOD_WLS_PLUGIN="mod_wl_24.so" \
    LD_LIBRARY_PATH="/root/lib" \
    WEBLOGIC_CLUSTER="server0:7002,server1:7002"

COPY $PLUGIN_PKG weblogic.conf /root/

RUN apt-get update && apt-get install -y unzip && \
    unzip /root/$PLUGIN_PKG -d $PLUGIN_HOME && \
    cat /root/weblogic.conf >> /usr/local/apache2/conf/httpd.conf && \
    rm /root/$PLUGIN_PKG /root/weblogic.conf
