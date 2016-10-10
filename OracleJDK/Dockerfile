# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
FROM oraclelinux:latest

MAINTAINER Bruno Borges <bruno.borges@oracle.com>

ARG JAVAVERSION
ARG JAVAUPDATEVERSION

ENV JAVA_HOME=/usr/java/jdk1.${JAVAVERSION}.0_${JAVAUPDATEVERSION}
ENV PATH=$PATH:${JAVA_HOME}/bin

ADD server-jre-${JAVAVERSION}u${JAVAUPDATEVERSION}-linux-x64.tar.gz /usr/java

RUN ln -s $JAVA_HOME /usr/java/latest && \
    ln -s $JAVA_HOME /usr/java/default && \
    alternatives --install /usr/bin/java java $JAVA_HOME/bin/java 20000 && \
    alternatives --install /usr/bin/javac javac $JAVA_HOME/bin/javac 20000 && \
    alternatives --install /usr/bin/jar jar $JAVA_HOME/bin/jar 20000

