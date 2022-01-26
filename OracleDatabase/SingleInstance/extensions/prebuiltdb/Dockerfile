# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
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
FROM ${BASE_IMAGE}

ARG ORACLE_SID
ARG ORACLE_PDB
ARG ORACLE_PWD
ARG ENABLE_ARCHIVELOG

# Option to enable archivelog in pre-built database
ENV ENABLE_ARCHIVELOG=${ENABLE_ARCHIVELOG:-false}
ENV ORACLE_SID=${ORACLE_SID:-ORCLCDB}
ENV ORACLE_PDB=${ORACLE_PDB:-ORCLPDB1}
ENV ORACLE_PWD=${ORACLE_PWD}

# Creating the database
# We disable INIT_SGA_PERCENTAGE so that the prebuiltdb does not store data about
# the memory of the builder inside of the container.
RUN INIT_SGA_PERCENTAGE="" $ORACLE_BASE/$RUN_FILE --nowait
