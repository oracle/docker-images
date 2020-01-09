# LICENSE UPL 1.0
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#

FROM oraclelinux:7-slim

# Note: If you are behind a web proxy, set the build variables for the build:
#       E.g.:  docker build --build-arg "https_proxy=..." --build-arg "http_proxy=..." --build-arg "no_proxy=..." ...

ARG GRAAL_VERSION=19.3.0
ARG JAVA_VERSION=java8
ENV LANG=en_US.UTF-8

ENV GRAALVM_PKG=https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-$GRAAL_VERSION/graalvm-ce-$JAVA_VERSION-linux-amd64-$GRAAL_VERSION.tar.gz \
    JAVA_HOME=/opt/graalvm-ce-$JAVA_VERSION-$GRAAL_VERSION/

RUN yum update -y oraclelinux-release-el7 \
    && yum install -y oraclelinux-developer-release-el7 oracle-softwarecollection-release-el7 \
    && yum-config-manager --enable ol7_developer \
    && yum-config-manager --enable ol7_developer_EPEL \
    && yum-config-manager --enable ol7_optional_latest \
    && yum install -y bzip2-devel ed gcc gcc-c++ gcc-gfortran gzip file fontconfig less libcurl-devel make openssl openssl-devel readline-devel tar vi which xz-devel zlib-devel \
    && yum install -y glibc-static libcxx libcxx-devel libstdc++-static zlib-static \
    && rm -rf /var/cache/yum

RUN fc-cache -f -v

ADD gu-wrapper.sh /usr/local/bin/gu

RUN set -eux \
    && curl --fail --silent --location --retry 3 ${GRAALVM_PKG} \
    | gunzip | tar x -C /opt/ \

    # Set alternative links
    && mkdir -p "/usr/java" \
    && ln -sfT "$JAVA_HOME" /usr/java/default \
    && ln -sfT "$JAVA_HOME" /usr/java/latest \
    && for bin in "$JAVA_HOME/bin/"*; do \
        base="$(basename "$bin")"; \
        [ ! -e "/usr/bin/$base" ]; \
        alternatives --install "/usr/bin/$base" "$base" "$bin" 20000; \
    done \

    && chmod +x /usr/local/bin/gu

CMD java -version
