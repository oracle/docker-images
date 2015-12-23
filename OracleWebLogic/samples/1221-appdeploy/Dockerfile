# LICENSE CDDL 1.0 + GPL 2.0
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic image built under 1221-domain with tag name '1221-domain'
#
# It will deploy any package defined in APP_PKG_FILE located in APP_PKG_LOCATION
# into the DOMAIN_HOME with name defined in APP_NAME 
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ sudo docker build -t 1221-appdeploy .
#

# Pull base image
# ---------------
FROM 1221-domain 

# Maintainer
# ----------
MAINTAINER Bruno Borges <bruno.borges@oracle.com>

# Define variables
ENV APP_NAME "sample"
ENV APP_PKG_FILE "sample.war"
ENV APP_PKG_LOCATION "/u01/oracle"

# Copy files and deploy in WLST Offline mode
COPY container-scripts/* /u01/oracle/
RUN sh appDeploy.sh

# Define default command to start WebLogic Admin Server
CMD ["startWebLogic.sh"]
