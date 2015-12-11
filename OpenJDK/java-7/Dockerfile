FROM oraclelinux:latest

MAINTAINER Bruno Borges <bruno.borges@oracle.com>

RUN yum -y install java-1.7.0-openjdk-devel && yum -y clean all && rm -rf /var/cache/yum/*

ENV JAVA_HOME /usr/lib/jvm/java-openjdk

CMD ["java", "-version"]
