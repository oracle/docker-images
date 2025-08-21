# LICENSE UPL 1.0
#
# Copyright (c) 1982-2024 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the base container image with pre-created database, intending improved startup in CI/CD pipelines
#
# REQUIREMENTS FOR THIS IMAGE
# ----------------------------------
# Oracle Single Instance Database container image version 19c onwards
#
# HOW TO BUILD THIS IMAGE
# -----------------------
#
# Run:
#      $ docker build -t <extended_image_name> . --build-arg BASE_IMAGE=21.3.0-ee
#

ARG BASE_IMAGE=oracle/database:21.3.0-ee
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

ARG ORACLE_SID
ARG ORACLE_PDB
ARG ORACLE_PWD
ARG ENABLE_ARCHIVELOG
ARG ENABLE_FORCE_LOGGING
ARG AUTO_MEM_CALCULATION

# Option to enable archivelog in pre-built database
ENV ENABLE_ARCHIVELOG=${ENABLE_ARCHIVELOG:-false}
ENV ENABLE_FORCE_LOGGING=${ENABLE_FORCE_LOGGING:-false}
ENV ORACLE_SID=${ORACLE_SID}
ENV ORACLE_PDB=${ORACLE_PDB}
ENV ORACLE_PWD=${ORACLE_PWD}
ENV AUTO_MEM_CALCULATION=${AUTO_MEM_CALCULATION:-false}

COPY --chown=oracle:dba setup/* "$ORACLE_BASE"/scripts/extensions/setup/

# Creating the database
RUN "$ORACLE_BASE/$RUN_FILE" --nowait
