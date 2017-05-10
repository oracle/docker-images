# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
FROM oraclelinux:7-slim

MAINTAINER Avi Miller <avi.miller@oracle.com>

ENV GRAALVM_PKG=graalvm-0.22-linux-amd64-jdk8.tar.gz \
    JAVA_HOME=/usr/graalvm-0.22/ \
    PATH=/usr/graalvm-0.22/bin:$PATH

ADD $GRAALVM_PKG /usr/

CMD ["graalvm", "--version"]
