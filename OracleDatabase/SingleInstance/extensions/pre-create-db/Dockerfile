# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# REQUIREMETNS FOR THIS IMAGE
# ----------------------------------
# Any release of prebuilt oracle/database base docker image
#
# HOW TO BUILD THIS IMAGE
# -----------------------
#
# Run:
#      $ docker build -t <extended_image_name> . \
#        --build-arg BASE_IMAGE=<base image> \
#        --build-arg PRE_CREATE_ORACLE_SID=<your CDB name> \
#        --build-arg PRE_CREATE_ORACLE_PDB=<your PDB name> \
#        --build-arg PRE_CREATE_ORACLE_PWD=<your password>
#

ARG BASE_IMAGE=12.2.0.1-ee
FROM ${BASE_IMAGE}

# Extn name
ARG EXTENSION_NAME=pre-create-db

ARG PRE_CREATE_ORACLE_SID
RUN if [[ -z "$PRE_CREATE_ORACLE_SID" ]] ; then echo No PRE_CREATE_ORACLE_SID found, please provide it in --build-arg; exit 1 ; fi
ARG PRE_CREATE_ORACLE_PDB
RUN if [[ -z "$PRE_CREATE_ORACLE_PDB" ]] ; then echo No PRE_CREATE_ORACLE_PDB found, please provide it in --build-arg; exit 1 ; fi
ARG PRE_CREATE_ORACLE_PWD
RUN if [[ -z "$PRE_CREATE_ORACLE_PWD" ]] ; then echo No PRE_CREATE_ORACLE_PWD found, please provide it in --build-arg; exit 1 ; fi

RUN echo "Creating a new SID/CDB: $PRE_CREATE_ORACLE_SID"
RUN echo "Creating a new PDB: $PRE_CREATE_ORACLE_PDB"
RUN echo "PASSWORD FOR SYS AND SYSTEM: $PRE_CREATE_ORACLE_PWD"

# Create database
RUN $ORACLE_BASE/$CREATE_DB_FILE $PRE_CREATE_ORACLE_SID $PRE_CREATE_ORACLE_PDB $PRE_CREATE_ORACLE_PWD
