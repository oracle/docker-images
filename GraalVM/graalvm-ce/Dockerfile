# LICENSE UPL 1.0
#
# Copyright (c) 2018 Oracle? and/or its affiliates. All rights reserved.
#
FROM oraclelinux:7-slim

MAINTAINER Mikhail Belous <belous.mikhail@gmail.com>

ENV GRAALVM_PKG=graalvm-ce-1.0.0-rc1-linux-amd64.tar.gz \
    JAVA_HOME=/usr/graalvm-ce-1.0.0-rc1/jre \
    PATH=/usr/graalvm-ce-1.0.0-rc1/bin:$PATH

ADD $GRAALVM_PKG /usr/

RUN yum -y install gcc && rm -rf /var/cache/yum && yum clean all && \
    alternatives --install /usr/bin/java  java  $JAVA_HOME/bin/java  20000 && \
    alternatives --install /usr/bin/javac javac $JAVA_HOME/bin/javac 20000 && \
    alternatives --install /usr/bin/jar   jar   $JAVA_HOME/bin/jar   20000

CMD ["java", "-version"]
