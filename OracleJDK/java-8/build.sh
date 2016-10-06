#!/bin/sh

export JAVAVERSION=8
export JAVASUBVERSION=101
export JAVAPATCHVERSION=b13

curl -v -j -k -L --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/${JAVAVERSION}u${JAVASUBVERSION}-${JAVAPATCHVERSION}/server-jre-${JAVAVERSION}u${JAVASUBVERSION}-linux-x64.tar.gz -o server-jre-${JAVAVERSION}u${JAVASUBVERSION}-linux-x64.tar.gz

docker build    --build-arg https_proxy \
       --build-arg http_proxy \
       --build-arg JAVAVERSION=${JAVAVERSION} \
       --build-arg JAVASUBVERSION=${JAVASUBVERSION} \
       --build-arg JAVAPATCHVERSION=${JAVAPATCHVERSION} \
       -t oracle/server-jdk:${JAVAVERSION}u${JAVASUBVERSION}-${JAVAPATCHVERSION} .
docker tag oracle/server-jdk:${JAVAVERSION}u${JAVASUBVERSION}-${JAVAPATCHVERSION} oracle/server-jdk:${JAVAVERSION}

