# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle OpenJDK 15
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
#
# (1) openjdk-15.xx_linux-x64_bin.tar.gz
#     Downloaded from https://jdk.java.net/15/
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Run:
#      $ docker build -t oracle/openjdk:15 .
#
# This command is already scripted in build.sh so you can alternatively run
#		$ bash build.sh
#

FROM oraclelinux:7-slim

MAINTAINER Aurelio Garcia-Ribeyro <aurelio.garciaribeyro@oracle.com>


ENV JAVA_PKG=https://download.java.net/java/GA/jdk15/779bf45e88a44cbd9ea6621d33e33db1/36/GPL/openjdk-15_linux-x64_bin.tar.gz \
	JAVA_SHA256=bb67cadee687d7b486583d03c9850342afea4593be4f436044d785fba9508fb7 \
	JAVA_VERSION=15 \
	JAVA_HOME=/usr/java/jdk-15 \
	LANG=en_US.UTF-8

ENV	PATH $JAVA_HOME/bin:$PATH
	
# Since the files is compressed as tar.gz first yum install gzip and tar
RUN set -eux; \
	yum install -y \
		gzip \
		tar \
		# JDK assumes freetype is available		
		freetype fontconfig \
	; \
	rm -rf /var/cache/yum ; \
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
	javac --version

CMD ["jshell"]



	



