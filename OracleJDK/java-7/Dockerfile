# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
#
FROM oraclelinux:7

MAINTAINER Bruno Borges <bruno.borges@oracle.com>

ENV JAVA_PKG=server-jre-7u80-linux-x64.tar.gz \
    JAVA_FOLDER=jdk1.7.0_80 \
    JAVA_HOME=/usr/java/default \
    PATH=$PATH:/usr/java/default/bin

ADD $JAVA_PKG /usr/java/

RUN ln -s /usr/java/$JAVA_FOLDER /usr/java/default && \
    ln -s /usr/java/$JAVA_FOLDER /usr/java/latest
