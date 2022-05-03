# Copyright (c) 2019, 2022 Oracle and/or its affiliates. 
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Server JRE 8
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
#
# (1) server-jre-8uXX-linux-x64.tar.gz
#     Download from https://www.oracle.com/java/technologies/javase-server-jre8-downloads.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ docker build -t oracle/serverjre:8 .
#
# This command is already scripted in build.sh so you can alternatively run
#		$ bash build.sh
#
# The builder image will be used to uncompress the tar.gz file with the Java Runtime.

FROM oraclelinux:7-slim as builder

MAINTAINER Aurelio Garcia-Ribeyro <aurelio.garciaribeyro@oracle.com>

# Since the files is compressed as tar.gz first yum install gzip and tar
RUN set -eux; \
	yum install -y \
		gzip \
		tar \
	; \
	rm -rf /var/cache/yum

# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8

# Environment variables for the builder image.  
# Required to validate that you are using the correct file

ENV JAVA_PKG=server-jre-8u333-linux-x64.tar.gz \
	JAVA_SHA256=e6383f75665f5674deeb7e5c366fc7c6fc93e990c638c224dc68c5ec2863b763 \
	JAVA_HOME=/usr/java/jdk-8

COPY $JAVA_PKG /tmp/jdk.tgz
RUN set -eux; \
	echo "$JAVA_SHA256 */tmp/jdk.tgz" | sha256sum -c -; \
	mkdir -p "$JAVA_HOME"; \
	tar --extract --file /tmp/jdk.tgz --directory "$JAVA_HOME" --strip-components 1; 

## Get a fresh version of SLIM for the final image

FROM oraclelinux:7-slim

# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8

ENV JAVA_VERSION=1.8.0_333 \
	JAVA_HOME=/usr/java/jdk-8 
	
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
	