#Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic sample 12213-domain.  You must first build the 12213-domain image
#
# It will create a DataSource as per container-scripts/datasource.properties
# It will create a JMS Server and Queue
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# This Oracle WebLogic domain image extends the Oracle WebLogic 12.2.1.3 domain image, you must first build the image go to ../12213-domain and  
# Run:
#      $ docker build -f Dockerfile -t 12213-weblogic-domain-in-volume .
#
# To build this image 
# Run:
#      $ docker build -t 12213-domain-with-resources .
#

# Pull base image
# ---------------
FROM 12213-weblogic-domain-in-volume

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# Copy files and deploy application in WLST Offline mode
COPY container-scripts/* /u01/oracle/

RUN wlst -loadProperties /u01/oracle/datasource.properties /u01/oracle/ds-deploy.py && \
    wlst /u01/oracle/jms-deploy.py
