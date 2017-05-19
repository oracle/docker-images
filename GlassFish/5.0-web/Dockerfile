# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
# 
# GlassFish on Docker with Oracle Linux and OpenJDK
FROM oraclelinux:latest

# Maintainer
MAINTAINER Arindam Bandyopadhyay<arindam.bandyopadhyay@oracle.com>

# Set environment variables and default password for user 'admin'
ENV GLASSFISH_PKG=latest-web.zip \
    GLASSFISH_URL=http://download.oracle.com/glassfish/5.0/nightly/latest-web.zip \
    GLASSFISH_HOME=/glassfish5 \
    PATH=$PATH:/glassfish5/bin \
    JAVA_HOME=/usr/lib/jvm/java-openjdk

# Install packages, download and extract GlassFish
# Setup password file
# Enable DAS
RUN yum -y install wget unzip java-1.8.0-openjdk-devel && \
    wget --quiet --no-check-certificate $GLASSFISH_URL && \
    unzip -o $GLASSFISH_PKG && \
    rm -f $GLASSFISH_PKG && \
    yum -y remove wget unzip && rm -rf /var/cache/yum/*

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Ports being exposed
EXPOSE 4848 8080 8181

# Start asadmin console and the domain
CMD ["asadmin", "start-domain", "-v"]
