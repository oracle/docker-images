# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
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
# Execute the "buildDockerImage.sh" shell script, with the name of the downloaded OGG filename.
# Example:
#      $ ./buildDockerImage.sh ~/Downloads/fbo_ggs_Linux_x64_shiphome.zip
#

ARG         BASE_IMAGE=container-registry.oracle.com/database/instantclient:12.2.0.1
FROM      ${BASE_IMAGE}
LABEL       Description="Oracle GoldenGate on Docker" \
            Maintainer="Stephen Balousek <stephen.balousek@oracle.com>"
user        root

ARG         OGG_VERSION
ARG         OGG_EDITION
ARG         OGG_TARFILE

ENV         JAVA_HOME=/usr/lib/jvm/jre \
            OGG_HOME=/u01/app/ogg \
            OGG_DEPLOY_BASE=/u02/ogg \
            PATH=$PATH:/u01/app/ogg:/u01/app/ogg/bin \
            OGG_VERSION=${OGG_VERSION} \
            OGG_EDITION=${OGG_EDITION}

ADD         ${OGG_TARFILE} \
            runOracleGoldenGate.sh ${OGG_HOME}/

RUN         if [[ -z "${OGG_VERSION}" || -z "${OGG_EDITION}" || -z "${OGG_TARFILE}" ]]; then \
                echo "----------------------------------------------------------------------------------" && \
                echo "-- Missing build argument for Dockerfile. See README.md for usage instructions. --" && \
                echo "----------------------------------------------------------------------------------" && \
                exit 1; \
            fi; \
#
# Initial setup
# - Optional proxy setup for Yum
# - The oracle:oinstall user must use the numeric identifiers 54321:54321
#
            [[ -z ${http_proxy} ]] || echo "proxy=${http_proxy}" >> /etc/yum.conf && \
            grep -q '^oinstall:x:54321' /etc/group  || groupadd -g 54321    oinstall        && \
            grep -q '^oracle:x:54321'   /etc/passwd || useradd  -u 54321 -g oinstall oracle && \
            mkdir -p              ${OGG_HOME} && \
            chown oracle:oinstall ${OGG_HOME}; \
#
# Additional installation for Oracle GoldenGate Standard Edition
# - 'vi' is used by the Oracle GoldenGate 'ggsci' utility to edit parameter
#    files and must be run from inside the container.
#
            if [[ "${OGG_EDITION}" == "standard" ]]; then \
                yum -y install util-linux vi && \
                yum -y clean  all; \
            fi; \
#
# Additional installation for Oracle GoldenGate Microservices Architecture
#
            if [[ "${OGG_EDITION}" == "microservices" ]]; then \
                yum -y --enablerepo *software_collections install openssl rh-nginx18 java-1.8.0-openjdk-headless && \
                yum -y clean  all && \
                ln -s /etc/opt/rh/rh-nginx18/nginx /etc/nginx && \
                sh /etc/ssl/certs/make-dummy-cert  /etc/nginx/ogg.pem && \
                mkdir -p              ${OGG_DEPLOY_BASE} && \
                chown oracle:oinstall ${OGG_DEPLOY_BASE}; \
            fi;

EXPOSE      443
VOLUME     ["${OGG_DEPLOY_BASE}" ]
WORKDIR     "${OGG_HOME}"
ENTRYPOINT ["sh", "-c", "exec ${OGG_HOME}/runOracleGoldenGate.sh"]
