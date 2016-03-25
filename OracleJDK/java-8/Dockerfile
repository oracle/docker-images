# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
FROM oraclelinux:latest

MAINTAINER Bruno Borges <bruno.borges@oracle.com>

ENV JAVA_PKG=server-jre-8u*-linux-x64.tar.gz \
    JAVA_HOME=/usr/java/default \
    PATH=$PATH:$JAVA_HOME/bin

ADD $JAVA_PKG /usr/java/

RUN ln -s $(ls -1 /usr/java) $JAVA_HOME
