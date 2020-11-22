# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle NoSQL Database Release 19.5.19 Community Edition

# Pull base image
# ---------------
FROM openjdk:14-oracle

LABEL "org.opencontainers.image.authors"="Anand Chandak <anand.chandak@oracle.com>" \
      "org.opencontainers.image.url"="https://github.com/oracle/docker-images" \
      "org.opencontainers.image.source"="https://github.com/oracle/docker-images/tree/master/NoSQL/19.5" \
      "org.opencontainers.image.vendor"="Oracle America, Inc" \
      "org.opencontainers.image.title"="Oracle NoSQL 19.5 Community Edition" \
      "org.opencontainers.image.description"="Oracle NoSQL Database provides \
      multi-terabyte distributed storage for key-value pairs, with scalable \
      throughput and great performance."

ENV VERSION="19.5.19" \
    KVHOME=/kv-19.5.19 \
    PACKAGE="kv-ce" \
    EXTENSION="zip" \
    BASE_URL="http://download.oracle.com/otn-pub/otn_software/nosql-database/" \
    _JAVA_OPTIONS="-Djava.security.egd=file:/dev/./urandom"

RUN yum -y install unzip && \
    curl -OLs "${BASE_URL}/${PACKAGE}-${VERSION}.${EXTENSION}" && \
    unzip "${PACKAGE}-${VERSION}.${EXTENSION}" && \
    rm "${PACKAGE}-${VERSION}.${EXTENSION}" && \
    yum -y remove unzip && rm -rf /var/cache/yum/*

VOLUME ["/kvroot"]

WORKDIR "$KVHOME"

EXPOSE 5000 5001 5010-5020

CMD ["java", "-jar", "lib/kvstore.jar", "kvlite", "-secure-config", "disable", "-root", "/kvroot"]
