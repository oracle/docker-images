# LICENSE UPL 1.0
#
# Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#

FROM oraclelinux:7-slim

MAINTAINER Manuel Zach <manuel.zach@oracle.com>

# Note: If you are behind a web proxy, set the build variables for the build:
#       E.g.:  docker build --build-arg "https_proxy=..." --build-arg "http_proxy=..." --build-arg "no_proxy=..." ...

ARG GRAAL_VERSION=1.0.0-rc2
ENV LANG=en_US.UTF-8

ENV GRAALVM_PKG=https://github.com/oracle/graal/releases/download/vm-$GRAAL_VERSION/graalvm-ce-$GRAAL_VERSION-linux-amd64.tar.gz \
    JAVA_HOME=/usr/graalvm-ce-$GRAAL_VERSION/ \
    PATH=/usr/graalvm-ce-$GRAAL_VERSION/bin:$PATH

RUN curl -o /etc/yum.repos.d/public-yum-ol7.repo http://yum.oracle.com/public-yum-ol7.repo \
    && yum-config-manager --enable ol7_developer_EPEL \
    && yum install -y gcc gcc-c++ gzip make openssl-devel tar vi zlib-devel \
    && yum install -y libcxx libcxx-devel \
    && yum clean all

RUN set -x \
    && curl --fail --silent --location --retry 3 ${GRAALVM_PKG} \
    | gunzip | tar x -C /usr/

RUN alternatives --install /usr/bin/java  java  $JAVA_HOME/bin/java  20000 \
    && alternatives --install /usr/bin/javac javac $JAVA_HOME/bin/javac 20000 \
    && alternatives --install /usr/bin/jar   jar   $JAVA_HOME/bin/jar   20000

