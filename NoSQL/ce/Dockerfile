# Copyright (c) 2022 Oracle and/or its affiliates
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
#
FROM openjdk:17-oraclelinux8

LABEL org.opencontainers.image.source = "https://github.com/oracle/docker-images"

ARG KV_VERSION=20.3.19
ARG DOWNLOAD_ROOT=http://download.oracle.com/otn-pub/otn_software/nosql-database
ARG DOWNLOAD_FILE=kv-ce-$KV_VERSION.zip
ARG DOWNLOAD_LINK=$DOWNLOAD_ROOT/$DOWNLOAD_FILE
ARG UNZIPPED_ONLY_LIB=kv-$KV_VERSION/lib

ENV KV_PROXY_PORT 8080

RUN microdnf install unzip hostname && \
    microdnf clean all

RUN curl -OLs  $DOWNLOAD_LINK  && \
    unzip $DOWNLOAD_FILE $UNZIPPED_ONLY_LIB/* && \
    rm -f $DOWNLOAD_FILE

WORKDIR "kv-$KV_VERSION"

RUN echo "KVHOST=\`hostname\`" >start-kvlite.sh  && \
    echo "java -jar lib/kvstore.jar kvlite  -secure-config disable -root /kvroot &" >>start-kvlite.sh && \
    echo "java -jar lib/httpproxy.jar -helperHosts \$KVHOST:5000 -storeName kvstore -httpPort \$KV_PROXY_PORT -verbose true" >>start-kvlite.sh

VOLUME ["/kvroot"]

CMD sh start-kvlite.sh
