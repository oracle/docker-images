# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
# Use ln instead of mv to decrease image size
FROM oraclelinux:latest

MAINTAINER Bruno Borges <bruno.borges@oracle.com>

ENV JAVA_PKG=server-jre-8u*-linux-x64.tar.gz \
    JAVA_HOME=/usr/java/default \
    PATH=$PATH:/usr/java/default/bin

ADD $JAVA_PKG /usr/java/

# Some scripts may not trust symlink and end up hardcoding path
# https://github.com/oracle/docker-images/commit/e234ae65f557bff33e4bb9c3ff59f6377a02a7d6
RUN ln -s $(ls -1 -d /usr/java/*) $JAVA_HOME 
