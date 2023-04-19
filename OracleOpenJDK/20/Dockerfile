# Copyright (c) 2022, 2023 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle OpenJDK 20 on Oracle Linux 8
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
#
# (1) openjdk-20.xx_linux-x64_bin.tar.gz
#     Downloaded from https://jdk.java.net/20/
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Run:
#      $ docker build -t oracle/openjdk:20 .
#
# This command is already scripted in build.sh so you can alternatively run
#		$ bash build.sh
#

FROM oraclelinux:8 

LABEL maintainer="Aurelio Garcia-Ribeyro <aurelio.garciaribeyro@oracle.com>"


ENV JAVA_URL=https://download.java.net/java/GA/jdk20.0.1/b4887098932d415489976708ad6d1a4b/9/GPL \
	JAVA_HOME=/usr/java/jdk-20 \
	LANG=en_US.UTF-8
	

# If you need the Java Version you can read it from the release file with 
#JAVA_VERSION=$(sed -n '/^JAVA_VERSION="/{s///;s/"//;p;}' "$JAVA_HOME"/release);
	
ENV	PATH $JAVA_HOME/bin:$PATH
	
# Since the files are compressed as tar.gz first dnf install tar. gzip is already in oraclelinux:8
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN set -eux; \
	dnf -y update; \
	dnf install -y \
		tar \
		# JDK assumes freetype is available		
		freetype fontconfig \
	; \
	rm -rf /var/cache/dnf; \
	ARCH="$(uname -m)" && \
	# Java uses just x64 in the name of the tarball
    if [ "$ARCH" = "x86_64" ]; \
        then ARCH="x64"; \
    fi && \
    JAVA_PKG="$JAVA_URL"/openjdk-20.0.1_linux-"${ARCH}"_bin.tar.gz ; \
	JAVA_SHA256="$(curl "$JAVA_PKG".sha256)" ; \ 
	curl --output /tmp/jdk.tgz "$JAVA_PKG" && \
	echo "$JAVA_SHA256" */tmp/jdk.tgz | sha256sum -c -; \
	mkdir -p "$JAVA_HOME"; \
	tar --extract --file /tmp/jdk.tgz --directory "$JAVA_HOME" --strip-components 1; \
	rm /tmp/jdk.tgz

RUN ln -sfT "$JAVA_HOME" /usr/java/default; \
	ln -sfT "$JAVA_HOME" /usr/java/latest; \
	for bin in "$JAVA_HOME"/bin/*; do \
		base="$(basename "$bin")"; \
		[ ! -e "/usr/bin/$base" ]; \
		alternatives --install "/usr/bin/$base" "$base" "$bin" 20000; \
	done; 

CMD ["jshell"]



	



