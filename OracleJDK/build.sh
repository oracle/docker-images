#!/bin/bash

#JAVA_DOWNLOAD_VERSIONS=$(ls server-jre-*-linux-x64.tar.gz)

function build_java
{
    for JAVA_DOWNLOAD in ${1};
    do
	echo ${JAVA_DOWNLOAD}
	if [[ ${JAVA_DOWNLOAD} =~ server-jre-([7-8])u([0-9]*)-linux-x64.tar.gz ]] ;
	then
	    export JAVAVERSION=${BASH_REMATCH[1]}
	    export JAVAUPDATEVERSION=${BASH_REMATCH[2]}
	    
	    echo "Building Java ${JAVAVERSION} image oracle/jdk:${JAVAVERSION}u${JAVAUPDATEVERSION}"
            docker build --build-arg JAVAVERSION=${JAVAVERSION} \
		   --build-arg JAVAUPDATEVERSION=${JAVAUPDATEVERSION} \
		   -t oracle/jdk:${JAVAVERSION}u${JAVAUPDATEVERSION} .
	fi
    done
    # Tag the latest
    echo "Tagging latest Java ${JAVAVERSION} image oracle/jdk:${JAVAVERSION}u${JAVAUPDATEVERSION} as oracle/jdk:${JAVAVERSION}"
    docker tag oracle/jdk:${JAVAVERSION}u${JAVAUPDATEVERSION} oracle/jdk:${JAVAVERSION}
}

build_java "$(ls server-jre-8*-linux-x64.tar.gz | sort)"
build_java "$(ls server-jre-7*-linux-x64.tar.gz | sort)"
