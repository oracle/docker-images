FROM oraclelinux:latest

MAINTAINER Bruno Borges <bruno.borges@oracle.com>

RUN yum -y install java-1.8.0-openjdk-devel-1.8.0.65 && yum -y clean all && rm -rf /var/cache/yum/*

ENV JAVA_HOME /usr/lib/jvm/java-openjdk

CMD ["java", "-version"]
