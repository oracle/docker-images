# Copyright (c) 2022 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Management Agent
#
# Base image of this dockerfile is Oracle Linux 7 Slim docker image.
# 
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) Management Agent software for Linux (Linux-x86_64/latest/oracle.mgmt_agent.zip)
#
# How to download the Management Agent software:
# https://docs.oracle.com/en-us/iaas/management-agents/doc/install-management-agent-chapter.html
# 
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ docker build -t oracle/mgmtagent-container .
#
# This command is already scripted in build.sh so you can alternatively run
#		$ bash build.sh
#

FROM oraclelinux:7-slim as builder

MAINTAINER Drupad Panchal <drupad.panchal@oracle.com>

# Labels
LABEL "provider"="Oracle"                                               \
      "issues"="https://github.com/oracle/docker-images/issues"         \
      "volume.data"="/opt/oracle"

# Install packages to install and run Management Agent
RUN set -eux; \
    yum -y install \
    java-1.8.0-openjdk-devel.x86_64 \
    sudo \
    unzip \
    && yum clean all

# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Copy container scripts to initialize the environment and start Management Agent
COPY ./container-scripts/*.sh /opt/oracle-mgmtagent-bootstrap/scripts/
RUN chmod 0544 /opt/oracle-mgmtagent-bootstrap/scripts/*.sh

# Copy Management Agent Installer Zip bundle
COPY ./oracle.mgmt_agent.zip /opt/oracle-mgmtagent-bootstrap/packages/

# Set watchdog as the entrypoint script (PID-1) for the container
ENTRYPOINT ["/opt/oracle-mgmtagent-bootstrap/scripts/watchdog.sh"]
