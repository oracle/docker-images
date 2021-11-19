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
#      $ docker build -t <extended_image_name> . --build-arg BASE_IMAGE=18.3.0-ee
#

ARG BASE_IMAGE=oracle/database:19.3.0-ee
FROM ${BASE_IMAGE}

ARG ORACLE_SID
ARG ORACLE_PDB
ARG ORACLE_PWD
ARG ENABLE_ARCHIVELOG

# Option to enable archivelog in pre-built database
ENV ENABLE_ARCHIVELOG={ENABLE_ARCHIVELOG:-false}

# Creating the database
RUN $ORACLE_BASE/$CREATE_DB_FILE ${ORACLE_SID:-ORCLCDB} ${ORACLE_PDB:-ORCLPDB1} $ORACLE_PWD && \
    if $ORACLE_BASE/$CHECK_DB_FILE; then touch $ORACLE_BASE/oradata/.${ORACLE_SID}${CHECKPOINT_FILE_EXTN}; fi