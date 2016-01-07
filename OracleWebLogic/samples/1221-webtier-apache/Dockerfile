# Example of Apache Web Server with WebLogic plugin for load balancing WebLogic on Docker Containers
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
# 
# Author: Bruno Borges <bruno.borges@oracle.com>
#
FROM httpd:2.4

ENV PLUGIN_PKG WLSPlugin12.2.1-Apache2.2-Apache2.4-Linux_x86_64-12.2.1.0.0.zip
ENV PLUGIN_HOME /root
ENV MOD_WLS_PLUGIN mod_wl_24.so
ENV LD_LIBRARY_PATH /root/lib

COPY $PLUGIN_PKG /root/
COPY update-httpd.sh /root/
COPY weblogic.conf /usr/local/apache2/conf/

RUN apt-get update && apt-get install -y unzip && \
    unzip /root/$PLUGIN_PKG -d $PLUGIN_HOME && \
    sh /root/update-httpd.sh && \
    rm /root/update-httpd.sh && \
    rm /root/$PLUGIN_PKG
