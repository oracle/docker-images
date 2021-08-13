# Copyright (c) 2021 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle OpenJDK 16
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
#
# (1) openjdk-16.xx_linux-x64_bin.tar.gz
#     Downloaded from https://jdk.java.net/16/
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Run:
#      $ docker build -t oracle/openjdk:16 .
#
# This command is already scripted in build.sh so you can alternatively run
#		$ bash build.sh
#

FROM oraclelinux:8-slim

MAINTAINER Aurelio Garcia-Ribeyro <aurelio.garciaribeyro@oracle.com>



ENV JAVA_PKG=https://download.java.net/java/GA/jdk16.0.2/d4a915d82b4c4fbb9bde534da945d746/7/GPL/openjdk-16.0.2_linux-x64_bin.tar.gz \
	JAVA_SHA256=6c714ded7d881ca54970ec949e283f43d673a142fda1de79b646ddd619da9c0c \
	JAVA_VERSION=16.0.2 \
	JAVA_HOME=/usr/java/jdk-16 \
	LANG=en_US.UTF-8

ENV	PATH $JAVA_HOME/bin:$PATH
	
# Since the files is compressed as tar.gz first yum install gzip and tar
RUN set -eux; \
	microdnf -y update; \
	microdnf install -y \
		gzip \
		tar \
		# JDK assumes freetype is available		
		freetype fontconfig \
	; \
	rm -rf /var/cache/yum; \
	curl --output /tmp/jdk.tgz "$JAVA_PKG" && \
	echo "$JAVA_SHA256 */tmp/jdk.tgz" | sha256sum -c -; \
	mkdir -p "$JAVA_HOME"; \
	tar --extract --file /tmp/jdk.tgz --directory "$JAVA_HOME" --strip-components 1; \
	rm /tmp/jdk.tgz

RUN ln -sfT "$JAVA_HOME" /usr/java/default; \
	ln -sfT "$JAVA_HOME" /usr/java/latest; \
	for bin in "$JAVA_HOME/bin/"*; do \
		base="$(basename "$bin")"; \
		[ ! -e "/usr/bin/$base" ]; \
		alternatives --install "/usr/bin/$base" "$base" "$bin" 20000; \
	done; \
# -Xshare:dump will create a CDS archive to improve startup in subsequent runs	
	java -Xshare:dump; \
	java --version; \
	javac --version; \
	grep VERSION= /etc/os-release

CMD ["jshell"]



	



