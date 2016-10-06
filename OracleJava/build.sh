#!/bin/bash -x

export JAVATYPE=${1}
export JAVAVERSION=${2}
export JAVASUBVERSION=${3}
export JAVAPATCHVERSION=${4}

docker build \
       --build-arg https_proxy \
       --build-arg http_proxy \
       --build-arg JAVATYPE=${JAVATYPE} \
       --build-arg JAVAVERSION=${JAVAVERSION} \
       --build-arg JAVASUBVERSION=${JAVASUBVERSION} \
       --build-arg JAVAPATCHVERSION=${JAVAPATCHVERSION} \
       -t oracle/${JAVATYPE}:${JAVAVERSION}${JAVASUBVERSION}-${JAVAPATCHVERSION} .

docker tag oracle/${JAVATYPE}:${JAVAVERSION}${JAVASUBVERSION}-${JAVAPATCHVERSION} oracle/${JAVATYPE}:${JAVAVERSION}
