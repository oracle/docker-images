# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
FROM oraclelinux:latest

MAINTAINER Bruno Borges <bruno.borges@oracle.com>

ARG JAVAVERSION
ARG JAVASUBVERSION
ARG JAVAPATCHVERSION

ENV JAVA_HOME /usr/java/jdk.1.${JAVAVERSION}.0_${JAVASUBVERSION}
ENV PATH=$PATH:${JAVA_HOME}/bin

ADD server-jre-${JAVAVERSION}u${JAVASUBVERSION}-linux-x64.tar.gz /usr/java