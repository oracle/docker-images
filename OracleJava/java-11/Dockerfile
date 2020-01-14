# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle JDK 11
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
#
# (1) jdk-11.XX_linux-x64_bin.tar.gz
#     Download from https://www.oracle.com/technetwork/java/javase/downloads/jdk11-downloads-5066655.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ docker build -t oracle/jdk:11 ..
#
# This command is already scripted on build.sh so you can alternatively run
#		$ bash build.sh

# The builder image will be use to uncompress the tar.gz file with the Java Runtime.

FROM oraclelinux:7-slim as builder

MAINTAINER Aurelio Garcia-Ribeyro <aurelio.garciaribeyro@oracle.com>

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

ENV JAVA_PKG=jdk-11.0.6_linux-x64_bin.tar.gz \
	JAVA_SHA256=a11bac55a96493556f349eead956b94d32f6a71031373771dca4cc72b89a82b4 \
	JAVA_HOME=/usr/java/jdk-11

##
COPY $JAVA_PKG /tmp/jdk.tgz
RUN set -eux; \
	echo "$JAVA_SHA256 */tmp/jdk.tgz" | sha256sum -c -; \
	mkdir -p "$JAVA_HOME"; \
	tar --extract --file /tmp/jdk.tgz --directory "$JAVA_HOME" --strip-components 1; \
	rm /tmp/jdk.tgz; 
	
## Get a fresh version of SLIM for the final image	
FROM oraclelinux:7-slim

# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8

ENV JAVA_VERSION=11.0.6 \
	JAVA_HOME=/usr/java/jdk-11

ENV	PATH $JAVA_HOME/bin:$PATH	

# Copy the uncompressed Java Runtime from the builder image
COPY --from=builder $JAVA_HOME $JAVA_HOME

RUN set -eux; \
	yum install -y \
# JDK assumes freetype is available		
		freetype fontconfig \
	; \
	rm -rf /var/cache/yum; \
	ln -sfT "$JAVA_HOME" /usr/java/default; \
	ln -sfT "$JAVA_HOME" /usr/java/latest; \
	for bin in "$JAVA_HOME/bin/"*; do \
		base="$(basename "$bin")"; \
		[ ! -e "/usr/bin/$base" ]; \
		alternatives --install "/usr/bin/$base" "$base" "$bin" 20000; \
	done; \
# -Xshare:dump will create a CDS archive to improve startup in subsequent runs	
	java -Xshare:dump; \
	java --version; \
	javac --version

CMD ["jshell"]
