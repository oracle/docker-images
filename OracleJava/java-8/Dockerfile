# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
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
#     Download from http://www.oracle.com/technetwork/java/javase/downloads/server-jre8-downloads-2133154.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ docker build -t oracle/serverjre:8 .
#
# This command is already scripted on build.sh so you can alternatively run
#		$ bash build.sh

# The builder image will be use to uncompress the tar.gz file with the Java Runtime.

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

ENV JAVA_PKG=server-jre-8u231-linux-x64.tar.gz \
	JAVA_SHA256=1d59a0ea3ef302d5851370b838693b0b6bde4c3f32015a4de0a9e4d202a988fc \
	JAVA_HOME=/usr/java/jdk-8

COPY $JAVA_PKG /tmp/jdk.tgz
RUN set -eux; \
	echo "$JAVA_SHA256 */tmp/jdk.tgz" | sha256sum -c -; \
	mkdir -p "$JAVA_HOME"; \
	tar --extract --file /tmp/jdk.tgz --directory "$JAVA_HOME" --strip-components 1; \
	rm /tmp/jdk.tgz

## Get a fresh version of SLIM for the final image

FROM oraclelinux:7-slim

# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8

ENV JAVA_VERSION=1.8.0_231 \
	JAVA_HOME=/usr/java/jdk-8 
	
ENV	PATH $JAVA_HOME/bin:$PATH

# Copy the uncompressed Java Runtime from the builder image
COPY --from=builder $JAVA_HOME $JAVA_HOME

##
RUN	ln -sfT "$JAVA_HOME" /usr/java/default; \
	ln -sfT "$JAVA_HOME" /usr/java/latest; \
	for bin in "$JAVA_HOME/bin/"*; do \
		base="$(basename "$bin")"; \
		[ ! -e "/usr/bin/$base" ]; \
		alternatives --install "/usr/bin/$base" "$base" "$bin" 20000; \
	done; \
# -Xshare:dump will create a CDS archive to improve startup in subsequent runs	
# the file will be stored as /usr/java/jdk-8/jre/lib/amd64/server/classes.jsa 
# See https://docs.oracle.com/javase/8/docs/technotes/guides/vm/class-data-sharing.html
	java -Xshare:dump; \
	java -version; \
	javac -version
	