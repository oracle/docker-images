#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

#
# Base image
#
ARG FMW_INFRA_IMAGE=oracle/fmw-infrastructure:12.2.1.4
FROM ${FMW_INFRA_IMAGE} as base

# Labels
# ------
LABEL "provider"="Oracle"                                             \
      "issues"="https://github.com/oracle/docker-images/issues"       \
      "maintainer"="Anil Arora <anil.arora@oracle.com>"               \
      "volume.data"="/u01/data"                                       \
      "volume.config"="/u01/config"                                   \
      "volume.temp"="/u01/tmp"                                        \
      "port.node.manager"="9556"                                      \
      "port.admin.server"="7001"                                      \
      "port.admin.server.ssl"="7002"                                  \
      "port.managed.server"="9000"                                    \
      "port.managed.server.ssl"="9001"                                \
      "port.agent"="1423"                                             \
      "port.agent.ssl"="6423"                                         \
      "port.eas.server"="9100"                                        \
      "port.eas.server.ssl"="9101"

USER root
RUN mkdir /u01/config /u01/data /u01/tmp && \
    chmod 750 /u01/config /u01/data /u01/tmp && \
    chown oracle:oracle /u01/config /u01/data /u01/tmp && \
    rm -rf /u01/container-scripts/* && \
    rm -rf /u01/oracle/container-scripts

# Essbase Prerequisites
RUN yum install -y gcc gcc-c++ \
                   libgcc libgcc.i686 \
                   hostname && \
    yum clean all && \
    rm -rf /var/cache/yum /var/tmp/yum-root* /var/lib/yum/history /var/log/yum.log

#
# Builder image
#
FROM base as builder

ARG ESSBASE_JAR=essbase-21.1.0.0.0-171-linux64.jar
ENV ESSBASE_JAR=${ESSBASE_JAR}

USER oracle
COPY --chown=oracle:oracle $ESSBASE_JAR install.file /u01/

RUN cd /u01 && \
    $JAVA_HOME/bin/java -jar /u01/$ESSBASE_JAR -silent -responseFile /u01/install.file \
                                               -invPtrLoc /u01/oraInst.loc \
                                               -jreLoc $JAVA_HOME \
                                               -ignoreSysPrereqs -force -novalidation \
                                               ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="Essbase Distribution" && \
    rm /u01/${ESSBASE_JAR} /u01/install.file && \
    rm -rf ${ORACLE_HOME}/cfgtoollogs && \
    rm -rf ${ORACLE_HOME}/.inventory/logs

# Apply Patches
COPY --chown=oracle:oracle patches /u01/patches
RUN /u01/patches/apply-patches.sh && \
    rm -rf /u01/patches

#
# Final image stage
#
FROM base

RUN mkdir /etc/essbase && \
    chmod 755 /etc/essbase

# Environment variables required for this build (do NOT change)
# (DOMAIN_NAME/HOME are reset here, to avoid FMW Infra environment leaking through)
# -------------------------------------------------------------
ENV DOMAIN_NAME="${DOMAIN_NAME:-essbase_domain}" \
    DOMAIN_ROOT="${DOMAIN_ROOT:-/u01/config/domains}" \
    DOMAIN_HOME="${DOMAIN_ROOT:-/u01/config/domains}/${DOMAIN_NAME:-essbase_domain}" \
    ARBORPATH="${ARBORPATH:-/u01/data/essbase}" \
    TMP_DIR="${TMP_DIR:-/u01/tmp}" \
    ADMIN_USERNAME="${ADMIN_USERNAME:-admin}" \
    ADMIN_PASSWORD="${ADMIN_PASSWORD:-welcome1}" \
    DATABASE_TYPE="${DATABASE_TYPE:-ORACLE}" \
    DATABASE_CONNECT_STRING="${DATABASE_CONNECT_STRING:-rcu-db:1521/PDBORCL}" \
    DATABASE_ADMIN_USERNAME="${DATABASE_ADMIN_USERNAME:-sys}" \
    DATABASE_WAIT_TIMEOUT="${DATABASE_WAIT_TIMEOUT:-0}" \
    DATABASE_SCHEMA_PREFIX="${DATABASE_SCHEMA_PREFIX:-ESS1}" \
    CREATE_SCHEMA="${CREATE_SCHEMA:-TRUE}" \
    DROP_SCHEMA="${DROP_SCHEMA:-FALSE}" \
    MACHINE_NAME_PREFIX="${MACHINE_NAME_PREFIX:-essbase_machine}" \
    NODE_MANAGER_PORT="${NODE_MANAGER_PORT:-9556}" \
    ADMIN_SERVER_PORT="${ADMIN_SERVER_PORT:-7001}" \
    ADMIN_SERVER_SSL_PORT="${ADMIN_SERVER_SSL_PORT:-7002}" \
    MANAGED_SERVER_PORT="${MANAGED_SERVER_PORT:-9000}" \
    MANAGED_SERVER_SSL_PORT="${MANAGED_SERVER_SSL_PORT:-9001}" \
    ESSBASE_CLUSTER_SIZE="${ESSBASE_CLUSTER_SIZE:-1}" \
    AGENT_PORT="${AGENT_PORT:-1423}" \
    AGENT_SSL_PORT="${AGENT_SSL_PORT:-6423}" \
    ESSBASE_SERVER_MIN_PORT="${ESSBASE_SERVER_MIN_PORT:-30768}" \
    ESSBASE_SERVER_MAX_PORT="${ESSBASE_SERVER_MAX_PORT:-31768}" \
    ENABLE_EAS="${ENABLE_EAS:-FALSE}" \
    EAS_SERVER_PORT="${EAS_SERVER_PORT:-9100}" \
    EAS_SERVER_SSL_PORT="${EAS_SERVER_SSL_PORT:-9101}" \
    IDENTITY_PROVIDER="${IDENTITY_PROVIDER:-EMBEDDED}" \
    SECURE_MODE="${SECURE_MODE:-FALSE}"

USER oracle
COPY --from=builder --chown=oracle:oracle /u01 /u01
COPY --chown=oracle:oracle container-scripts /u01/container-scripts
COPY etc /etc

# Healthcheck
HEALTHCHECK --start-period=3m --interval=30s --timeout=30s CMD ["/u01/container-scripts/healthcheck.sh"]

WORKDIR ${ORACLE_HOME}
CMD ["/u01/container-scripts/createAndStartDomain.sh"]
