# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle NoSQL Database Release 4.4.6 Enterprise Edition
# 
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) kv-ee-4.4.6.tar.gz
#     Download Oracle NoSQL Database Enterprise Edition for Linux x64
#     http://www.oracle.com/technetwork/database/database-technologies/nosqldb/downloads/index.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files (in tar.gz format) in the same directory as this Dockerfile
# Run: 
#      $ docker build -t oracle/nosqlee:4.4.6 . 
#
# Pull base image
# ---------------
FROM oracle/serverjre:8

MAINTAINER Mayuresh A Nirhali <mayuresh.nirhali@oracle.com>

ENV VERSION="4.4.6" \
    KVHOME=/kv-4.4.6 \
    PACKAGE="kv-ee" \
    EXTENSION="tar.gz" \
    _JAVA_OPTIONS="-Djava.security.egd=file:/dev/./urandom"

ADD ${PACKAGE}-${VERSION}.${EXTENSION} /
 
VOLUME ["/kvroot"]

WORKDIR "$KVHOME"

EXPOSE 5000 5010-5020

CMD ["java", "-jar", "lib/kvstore.jar", "kvlite", "-secure-config", "disable", "-root", "/kvroot"]
