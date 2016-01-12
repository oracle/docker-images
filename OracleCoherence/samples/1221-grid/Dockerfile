# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic image by creating a sample domain.
#
# Util scripts are copied into the image enabling users to plug NodeManager 
# automatically into the AdminServer running on another container.
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ sudo docker build -t 1221-domain .
#

# Pull base image
# ---------------
FROM oracle/coherence:12.2.1-quickinstall 

# Maintainer
# ----------
MAINTAINER Bruno Borges <bruno.borges@oracle.com>

# Coherence Configuration
# ----------------------------------------------------------
ENV CLUSTER_NAME "Cluster-Docker"

# Add files required to build this image
COPY container-scripts/* /config/

# Define default command to start bash. 
ENTRYPOINT ["/config/entrypoint.sh"]

CMD ["server"]
