# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
FROM oraclelinux:latest

MAINTAINER Bruno Borges <bruno.borges@oracle.com>

ARG JAVATYPE
ARG JAVAVERSION
ARG JAVASUBVERSION
ARG JAVAPATCHVERSION

ENV JAVA_HOME /usr/java/${JAVATYPE}1.${JAVAVERSION}.0_${JAVASUBVERSION}

RUN curl -v -j -k -L --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/${JAVAVERSION}${JAVASUBVERSION}-${JAVAPATCHVERSION}/${JAVATYPE}-${JAVAVERSION}${JAVASUBVERSION}-linux-x64.rpm -o ${JAVATYPE}-linux-x64.rpm && rpm -i ${JAVATYPE}-linux-x64.rpm && rm ${JAVATYPE}-linux-x64.rpm



