# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
# 
FROM oracle/openjdk:8

MAINTAINER Mayuresh A Nirhali <mayuresh.nirhali@oracle.com>

ENV VERSION="4.3.11" \
    KVHOME=/kv-4.3.11 \
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
