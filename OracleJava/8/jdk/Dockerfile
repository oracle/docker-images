# Copyright (c) 2023 Oracle and/or its affiliates. 
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle JDK 8 on Oracle Linux 7
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
#
# (1) jdk-8uXX-linux-x64.tar.gz or jdk-8uXX-linux-aarch64.tar.gz
#     Download from https://www.oracle.com/java/technologies/downloads/#java8
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put the downloaded file in the same directory as this Dockerfile
# Run:
#      $ docker build -t oracle/jdk:8 .
#
# This command is already scripted in build.sh so you can alternatively run
#		$ bash build.sh
#
# The builder image will be used to uncompress the tar.gz file with the Java Runtime.

FROM oraclelinux:7-slim as builder

LABEL maintainer="Aurelio Garcia-Ribeyro <aurelio.garciaribeyro@oracle.com>"

# Since the files is compressed as tar.gz first yum install gzip and tar
RUN yum install -y gzip tar

# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8

# Environment variables for the builder image.
# Required to validate that you are using the correct file

ENV JAVA_HOME=/usr/java/jdk-8

COPY jdk-8u*.tar.gz /tmp/
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN set -eux; \
	ARCH="$(uname -m)" && \
    if [ "$ARCH" = "x86_64" ]; \
    then \
		mv "$(ls /tmp/jdk-8*-linux-x64.tar.gz)" /tmp/jdk.tar.gz ; \
        JAVA_SHA256=6210799322de9316e16ec884e6904eab14017bc98725a85a5b66071be1dc1596 ; \
    else \
	    mv "$(ls /tmp/jdk-8*-linux-aarch64.tar.gz)" /tmp/jdk.tar.gz ; \
    	JAVA_SHA256=29c0543af33986667122cdcc0cc70b17dc4b3e53a9115149b531c8e3270d301d ; \    	
    fi && \
	echo "$JAVA_SHA256 */tmp/jdk.tar.gz" | sha256sum -c -; \
	mkdir -p "$JAVA_HOME"; \
	tar --extract --file /tmp/jdk.tar.gz --directory "$JAVA_HOME" --strip-components 1


## Get a fresh version of SLIM for the final image
FROM oraclelinux:7-slim

# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8

ENV JAVA_HOME=/usr/java/jdk-8 
	
ENV	PATH $JAVA_HOME/bin:$PATH

# Copy the uncompressed Java Runtime from the builder image
COPY --from=builder $JAVA_HOME $JAVA_HOME

##
RUN	yum -y update; \
	rm -rf /var/cache/yum; \
	ln -sfT "$JAVA_HOME" /usr/java/default; \
	ln -sfT "$JAVA_HOME" /usr/java/latest; \
	for bin in "$JAVA_HOME/bin/"*; do \
		base="$(basename "$bin")"; \
		[ ! -e "/usr/bin/$base" ]; \
		alternatives --install "/usr/bin/$base" "$base" "$bin" 20000; \
	done; \
# -Xshare:dump will create a CDS archive to improve startup in subsequent runs	
# the file will be stored as /usr/java/jdk-8/jre/lib/amd64/server/classes.jsa 
# See https://docs.oracle.com/javase/8/docs/technotes/guides/vm/class-data-sharing.html
	java -Xshare:dump;
	