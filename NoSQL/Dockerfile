FROM oracle/openjdk:latest

MAINTAINER Bruno Borges <bruno.borges@oracle.com>

ENV VERSION "3.4.7"
ENV PACKAGE "kv-ce"
ENV EXTENSION "zip"
ENV BASE_URL "http://download.oracle.com/otn-pub/otn_software/nosql-database/"

RUN yum -y install unzip
RUN curl -OL "${BASE_URL}/${PACKAGE}-${VERSION}.${EXTENSION}"
RUN unzip "${PACKAGE}-${VERSION}.${EXTENSION}"
RUN rm "${PACKAGE}-${VERSION}.${EXTENSION}"
RUN yum -y remove unzip && yum -y clean all && rm -rf /var/cache/yum/*

WORKDIR "/kv-${VERSION}"

CMD ["java", "-jar", "lib/kvstore.jar", "kvlite"]
