# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for pre-built database for gaining speedup in CI/CD pipelines
#
# REQUIREMETNS FOR THIS IMAGE
# ----------------------------------
# Any release of prebuilt oracle/database base docker image
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
RUN $ORACLE_BASE/$RUN_FILE --nowait
