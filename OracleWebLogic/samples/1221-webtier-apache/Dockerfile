# Example of Apache Web Server with WebLogic plugin for load balancing WebLogic on Docker Containers
#
# author: Bruno Borges <bruno.borges@oracle.com>
#
FROM httpd:2.4

ENV PLUGIN_PKG WLSPlugin12.2.1-Apache2.2-Apache2.4-Linux_x86_64-12.2.1.0.0.zip
ENV PLUGIN_HOME /root
ENV MOD_WLS_PLUGIN mod_wl_24.so
ENV LD_LIBRARY_PATH /root/lib/
ENV WEBLOGIC_CLUSTER "wlsadmin:8001"

COPY $PLUGIN_PKG /root/
COPY httpd.conf /usr/local/apache2/conf/httpd.conf
COPY weblogic.conf /usr/local/apache2/conf/

RUN apt-get update && \
    apt-get install -y unzip && \
    unzip $PLUGIN_HOME/$PLUGIN_PKG -d $PLUGIN_HOME 
