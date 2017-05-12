# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
FROM oraclelinux:7-slim

MAINTAINER Avi Miller <avi.miller@oracle.com>

ENV GRAALVM_PKG=graalvm-0.22-linux-amd64-jdk8.tar.gz \
    JAVA_HOME=/usr/graalvm-0.22/jdk \
    PATH=/usr/graalvm-0.22/bin:$PATH

ADD $GRAALVM_PKG /usr/

RUN yum -y install libgomp gcc && yum clean all && \
    alternatives --install /usr/bin/java  java  $JAVA_HOME/bin/java  20000 && \
    alternatives --install /usr/bin/javac javac $JAVA_HOME/bin/javac 20000 && \
    alternatives --install /usr/bin/jar   jar   $JAVA_HOME/bin/jar   20000

CMD ["graalvm", "--version"]
