# Copyright (c) 2017 Oracle and/or its affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

#
# ORACLE GOLDENGATE DOCKER PROJECT
# --------------------------------
#
# Dockerfile for Oracle GoldenGate
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
#
# From http://www.oracle.com/technetwork/middleware/goldengate/downloads/index.html
#  Download the file for "Oracle GoldenGate 12.x.x.x.x for Oracle on Linux x86-64"
#    - fbo_ggs_Linux_x64_shiphome.zip
#
# HOW TO BUILD THIS IMAGE
# -----------------------
#
# Execute the "dockerBuild.sh" shell script, with the name of the downloaded OGG filename.
# Example:
#      $ ./dockerBuild.sh ~/Downloads/fbo_ggs_Linux_x64_shiphome.zip
#

ARG         BASE_IMAGE=oracle/instantclient:12.2.0.1
FROM      ${BASE_IMAGE}
LABEL       Description="Oracle GoldenGate on Docker" \
            Maintainer="Stephen Balousek <stephen.balousek@oracle.com>"
USER        root

ARG         OGG_VERSION
ARG         OGG_EDITION
ARG         OGG_TARFILE
ARG         BASE_COMMAND

ENV         JAVA_HOME=/usr/lib/jvm/jre \
            OGG_HOME=/u01/app/ogg \
            OGG_DEPLOY_BASE=/u02/ogg \
            PATH=/u01/app/ogg:/u01/app/ogg/bin:/usr/lib/jvm/jre/bin:${PATH} \
            LD_LIBRARY_PATH=/usr/lib/jvm/jre/lib/amd64/server:${LD_LIBRARY_PATH} \
            OGG_VERSION=${OGG_VERSION} \
            OGG_EDITION=${OGG_EDITION} \
            BASE_COMMAND=${BASE_COMMAND}

ADD         ${OGG_TARFILE} ${OGG_HOME}/
COPY        runOracleGoldenGate.sh /

#
# Initial setup
# - This image will be smaller if the oracle:oinstall user has the numeric identifiers 54321:54321
# - 'vi' is used by the Oracle GoldenGate 'ggsci' utility to edit parameter
#    files and must be run from inside the container.
# - Installation of additional software packages depends on the value of ${OGG_EDITION}
#
RUN         if [[ -z "${OGG_VERSION}" || -z "${OGG_EDITION}" || -z "${OGG_TARFILE}" ]]; then \
                echo "----------------------------------------------------------------------------------" && \
                echo "-- Missing build argument for Dockerfile. See README.md for usage instructions. --" && \
                echo "----------------------------------------------------------------------------------" && \
                exit 1; \
            fi; \
            groupadd -g 54321    oinstall        || /bin/true; \
            useradd  -u 54321 -g oinstall oracle || /bin/true; \
            chown oracle:oinstall ${OGG_HOME}; \
            if [[ $(find ${OGG_HOME} -mindepth 1 -maxdepth 1 -user 54321 -group 54321 2>/dev/null | wc -l) == "0" ]]; then \
                echo "----------------------------------------------------------------------------------" && \
                echo "-- OGG_TARFILE '${OGG_TARFILE}' not using UID:GID of 54321:54321"                   && \
                echo "-- Resulting Docker image will be larger than necessary.                        --" && \
                echo "----------------------------------------------------------------------------------" && \
                chown -R oracle:oinstall ${OGG_HOME}; \
            fi; \
            if [[ "${OGG_EDITION}" == "standard" ]]; then \
                yum -y install util-linux vi java-1.8.0-openjdk-headless && \
                rm -rf /var/cache/yum; \
            fi; \
            if [[ "${OGG_EDITION}" == "microservices" ]]; then \
                . /etc/os-release && MAJOR_VERSION="${VERSION/.*/}" && \
                yum -y --enablerepo ol${MAJOR_VERSION}_software_collections install openssl rh-nginx18 java-1.8.0-openjdk-headless && \
                rm -rf /var/cache/yum && \
                ln -s /etc/opt/rh/rh-nginx18/nginx /etc/nginx && \
                sh /etc/ssl/certs/make-dummy-cert  /etc/nginx/ogg.pem && \
                mkdir -p              ${OGG_DEPLOY_BASE} && \
                chown oracle:oinstall ${OGG_DEPLOY_BASE}; \
            fi;

EXPOSE      443
VOLUME     ["${OGG_DEPLOY_BASE}" ]
WORKDIR     "${OGG_HOME}"
ENTRYPOINT ["/runOracleGoldenGate.sh"]
