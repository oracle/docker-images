# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
# 
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic domain built under 12212-domain with tag name '12212-domain'
#
# It will enable an SSL administration port for use with all servers in the domain to separate administration traffic 
# from application traffic in your domain.
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Run: 
#      $ docker build -t 12212-admin-port .
#

# Pull base image
# ---------------
FROM 12212-domain:latest

# Maintainer
# ----------
MAINTAINER Amy Moon <amy.roh@oracle.com>

# Define variables
ENV CONFIG_JVM_ARGS="-Dweblogic.security.SSL.ignoreHostnameVerification=true -Dweblogic.security.TrustKeyStore=DemoTrust"

# Copy files and deploy application in WLST Offline mode
COPY container-scripts/* /u01/oracle/

RUN wlst /u01/oracle/enable-admin-port.py
