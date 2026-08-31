# hadolint global ignore=DL3006,DL3061
# LICENSE UPL 1.0
#
# Copyright (c) 2024-2026 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Database with Fast Fail Over support
#
# REQUIREMETNS FOR THIS IMAGE
# ----------------------------------
# Any release of prebuilt oracle/database base docker image
#
# HOW TO BUILD THIS IMAGE
# -----------------------
#
# Run:
#      $ docker build -t <extended_image_name> . --build-arg BASE_IMAGE=oracle/database:23.26.0-ee
#

ARG BASE_IMAGE=oracle/database:23.26.0-ee

# Pull base image (ARG before FROM only; no USER before FROM — breaks Podman 5)
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

USER oracle

# Extn name
ARG EXTENSION_NAME=truecache
ENV CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV  SETUPTC="setup.sh" \
     BLOBREADER="blobReader.py" \
     CREATE_TC_SVCS_SCRIPT="createService.sh" \
     CREATE_BLOB_SCRIPT="createBlob.sh" \
     DBCA_UTILS_SCRIPT="dbcaUtils.sh" \
     REGISTER_TC_SVCS_SCRIPT="registerService.sh" \
     PRIMARY_TC_SERVICE_SCRIPT="configure-primary-truecache-service.sh" \
     TC_CHECK_DB_STATUS_SCRIPT="checkDBStatus.sh" \
     TC_CHECK_DB_LOCK_WRAPPER="checkDBLockStatus.sh" \
     TC_CREATE_DB_WRAPPER="createDB.truecache-wrapper.sh" \
     CREATE_DB_FILE="createDB.truecache-wrapper.sh"

# backup original runOracle
RUN if test -e "$ORACLE_BASE/$RUN_FILE.orig"; then EXTN='extended'; else EXTN='orig'; fi ; \
    mv "$ORACLE_BASE/$RUN_FILE" "$ORACLE_BASE/$RUN_FILE.$EXTN"

# Copy updated scripts for TC support
# dbcaUtils.sh is required by createBlob.sh and createService.sh (same directory source)
COPY --chown=oracle:dba $RUN_FILE $SETUPTC $BLOBREADER $CREATE_TC_SVCS_SCRIPT $CREATE_BLOB_SCRIPT $DBCA_UTILS_SCRIPT $ORACLE_BASE/
RUN   mv "$ORACLE_BASE/$RUN_FILE" "$ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME" 
COPY  --chown=oracle:dba $REGISTER_TC_SVCS_SCRIPT $ORACLE_BASE/scripts/extensions/setup/
COPY  --chown=oracle:dba $PRIMARY_TC_SERVICE_SCRIPT /home/oracle/configure-primary-truecache-service.sh
RUN   if [ -f /opt/oracle/scripts/base/checkDBStatus.sh ]; then \
         mv /opt/oracle/scripts/base/checkDBStatus.sh /opt/oracle/scripts/base/checkDBStatus.sh.orig; \
      fi
COPY  --chown=oracle:dba $TC_CHECK_DB_STATUS_SCRIPT /opt/oracle/scripts/base/checkDBStatus.sh
RUN   if [ -f /opt/oracle/scripts/extensions/k8s/checkDBLockStatus.sh ]; then \
         mv /opt/oracle/scripts/extensions/k8s/checkDBLockStatus.sh /opt/oracle/scripts/extensions/k8s/checkDBLockStatus.sh.orig; \
      fi
COPY  --chown=oracle:dba $TC_CHECK_DB_LOCK_WRAPPER /opt/oracle/scripts/extensions/k8s/checkDBLockStatus.sh
COPY  --chown=oracle:dba $TC_CREATE_DB_WRAPPER /opt/oracle/scripts/base/

# Set perms and append a call to main runOracle
RUN if test -e "$ORACLE_BASE/$RUN_FILE.extended"; then \
        mv "$ORACLE_BASE/$RUN_FILE.extended" "$ORACLE_BASE/$RUN_FILE" ; \
    else echo ". $ORACLE_BASE/$RUN_FILE.orig" > "$ORACLE_BASE/$RUN_FILE" ; fi ; \
    if ! grep "$RUN_FILE.$EXTENSION_NAME" "$ORACLE_BASE/$RUN_FILE"; then \
        sed  -i "1i . $ORACLE_BASE/$RUN_FILE.$EXTENSION_NAME" "$ORACLE_BASE/$RUN_FILE"; \
    fi && \
    chmod ug+x "$ORACLE_BASE"/*.sh "/opt/oracle/scripts/base/$TC_CREATE_DB_WRAPPER" "/opt/oracle/scripts/base/$TC_CHECK_DB_STATUS_SCRIPT" "/opt/oracle/scripts/extensions/k8s/$TC_CHECK_DB_LOCK_WRAPPER" "/home/oracle/configure-primary-truecache-service.sh" && sync
