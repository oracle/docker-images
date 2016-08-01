# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
FROM oraclelinux:latest

MAINTAINER Bruno Borges <bruno.borges@oracle.com>

ENV JAVA_PKG=server-jre-8u*-linux-x64.tar.gz 

ADD $JAVA_PKG /usr/java/

RUN alternatives --install /usr/bin/java java $(ls -1 -d /usr/java/*)/bin/java 20000 && \
    alternatives --install /usr/bin/javac javac $(ls -1 -d /usr/java/*)/bin/javac 20000 && \
    alternatives --install /usr/bin/jar jar $(ls -1 -d /usr/java/*)/bin/jar 20000
