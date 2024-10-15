# Copyright (c) 2020, 2024 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle JDK 17 on Oracle Linux 8
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) jdk-17.XX_linux-x64_bin.tar.gz or jdk-17.XX_linux-aarch64_bin.tar.gz
#     Download from https://www.oracle.com/java/technologies/downloads
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ docker build -t oracle/jdk:17 .
#
# This command is already scripted in build.sh so you can alternatively run
#		$ bash build.sh
#
# The builder image will be used to uncompress the tar.gz file with the Java Runtime.

FROM oraclelinux:8 as builder

LABEL maintainer="Aurelio Garcia-Ribeyro <aurelio.garciaribeyro@oracle.com>"

# Since the files are compressed as tar.gz first dnf install tar. gzip is already in oraclelinux:8
RUN dnf install -y tar

# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8

# Environment variables for the builder image.
# Required to validate that you are using the correct file

ENV JAVA_HOME=/usr/java/jdk-17

##
COPY *.tar.gz /tmp/
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN set -eux; \
	ARCH="$(uname -m)" && \
    if [ "$ARCH" = "x86_64" ]; \
    then \
	mv "$(ls /tmp/jdk-17*_linux-x64_bin.tar.gz)" /tmp/jdk.tar.gz ; \
        JAVA_SHA256=f7a6fdebeb11840e1f5314bc330feb75b67e52491cf39073dbf3e51e3889ff08 ; \
    else \
	mv "$(ls /tmp/jdk-17*_linux-aarch64_bin.tar.gz)" /tmp/jdk.tar.gz ; \
    	JAVA_SHA256=277e0010e7b17583e63827f9537a153ea79cb4b6ca28d523cd8a82f14a24a769 ; \
    fi && \
	echo "$JAVA_SHA256 */tmp/jdk.tar.gz" | sha256sum -c -; \
	mkdir -p "$JAVA_HOME"; \
	tar --extract --file /tmp/jdk.tar.gz --directory "$JAVA_HOME" --strip-components 1
	
## Get a fresh version of OL8 for the final image	
FROM oraclelinux:8

# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8
ENV	JAVA_HOME=/usr/java/jdk-17
ENV	PATH $JAVA_HOME/bin:$PATH	

# If you need the Java Version you can read it from the release file with 
# JAVA_VERSION=$(sed -n '/^JAVA_VERSION="/{s///;s/"//;p;}' "$JAVA_HOME"/release);

# Copy the uncompressed Java Runtime from the builder image
COPY --from=builder $JAVA_HOME $JAVA_HOME

RUN set -eux; \
# Ensure we get the latest OL 8 updates available at build time
	dnf -y update; \
# JDK assumes freetype is available	
	dnf install -y \
		freetype fontconfig \
	; \
	rm -rf /var/cache/dnf; \
	ln -sfT "$JAVA_HOME" /usr/java/default; \
	ln -sfT "$JAVA_HOME" /usr/java/latest; \
	for bin in "$JAVA_HOME/bin/"*; do \
		base="$(basename "$bin")"; \
		[ ! -e "/usr/bin/$base" ]; \
		alternatives --install "/usr/bin/$base" "$base" "$bin" 20000; \
	done;
	
CMD ["jshell"]
