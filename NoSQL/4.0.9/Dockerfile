# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
# 
FROM oracle/openjdk:latest

MAINTAINER Bruno Borges <bruno.borges@oracle.com>

ENV VERSION="4.0.9" \
    KVHOME=/kv-4.0.9 \
    PACKAGE="kv-ce" \
    EXTENSION="zip" \
    BASE_URL="http://download.oracle.com/otn-pub/otn_software/nosql-database/" \
    KVROOT=/var/kvroot \
    _JAVA_OPTIONS="-Djava.security.egd=file:/dev/./urandom"
 
RUN yum -y install unzip && \
    mkdir "${KVROOT}" && \
    curl -OLs "${BASE_URL}/${PACKAGE}-${VERSION}.${EXTENSION}" && \
    unzip "${PACKAGE}-${VERSION}.${EXTENSION}" && \
    rm "${PACKAGE}-${VERSION}.${EXTENSION}" && \
    yum -y remove unzip && rm -rf /var/cache/yum/*
 
WORKDIR "/kv-${VERSION}"
 
EXPOSE 5000 5001 5010-5020

CMD ["java", "-jar", "lib/kvstore.jar", "kvlite"]
