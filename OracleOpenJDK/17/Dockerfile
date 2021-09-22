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
# (1) openjdk-17.xx_linux-x64_bin.tar.gz
#     Downloaded from https://jdk.java.net/16/
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Run:
#      $ docker build -t oracle/openjdk:17 .
#
# This command is already scripted in build.sh so you can alternatively run
#		$ bash build.sh
#

FROM oraclelinux:8

MAINTAINER Aurelio Garcia-Ribeyro <aurelio.garciaribeyro@oracle.com>

ENV JAVA_PKG=https://download.java.net/java/GA/jdk17/0d483333a00540d886896bac774ff48b/35/GPL/openjdk-17_linux-x64_bin.tar.gz \
	JAVA_HOME=/usr/java/jdk-17 \
	LANG=en_US.UTF-8

# If you need the Java Version you can read it from the release file with 
#JAVA_VERSION=$(sed -n '/^JAVA_VERSION="/{s///;s/"//;p;}' "$JAVA_HOME"/release);
	
ENV	PATH $JAVA_HOME/bin:$PATH
	

# Since the files are compressed as tar.gz first dnf install tar. gzip is already in oraclelinux:8
RUN set -eux; \
	dnf -y update; \
	dnf install -y \
		tar \
		# JDK assumes freetype is available		
		freetype fontconfig \
	; \
	rm -rf /var/cache/dnf; \
	JAVA_SHA256=$(curl "$JAVA_PKG".sha256) ; \ 
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
	done; 

CMD ["jshell"]



	



