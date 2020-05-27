#Copyright (c) 2014, 2020, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle FMW Infrastructure 12.2.1.4
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# The Oracle FMW Infrastructure image extends the Oracle WebLogic Infrastructure 12.2.1.4 image, you must first build the Oracle WebLogic Infrastructure image.
# Run:
#      $ docker build -f Dockerfile -t oracle/fmw-infrastructure:12.2.1.4 .
#
# IMPORTANT
# ---------
# The resulting image of this Dockerfile contains a FMW Infra Base Domain.
#
# Extend base JRE image
# You must build the image by using the Dockerfile in GitHub project `../../../OracleJava/java8`
# ----------------------------------------------------------------------------------------------
FROM oracle/serverjre:8 as builder

# Labels
# ------
LABEL "provider"="Oracle"                                               \
      "maintainer"="Monica Riccelli <monica.riccelli@oracle.com>"       \
      "issues"="https://github.com/oracle/docker-images/issues"         \
      "port.admin.listen"="7001"                                        \
      "port.administration"="9002"                                      \
      "port.managed.server"="8001"

# Common environment variables required for this build
# ----------------------------------------------------
ENV ORACLE_HOME=/u01/oracle \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
    PATH=$PATH:${JAVA_HOME}/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin

# Setup subdirectory for FMW install package and container-scripts
# -----------------------------------------------------------------
RUN mkdir -p /u01 && \
    chmod a+xr /u01 && \
    useradd -b /u01 -d /u01/oracle -m -s /bin/bash oracle

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV FMW_PKG=fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip \
    FMW_JAR=fmw_12.2.1.4.0_infrastructure.jar

# Copy packages
# -------------
COPY $FMW_PKG install.file oraInst.loc /u01/
RUN chown oracle:oracle -R /u01

# Install
# ------------------------------------------------------------
USER oracle
RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$FMW_PKG && cd - && \
    $JAVA_HOME/bin/java -jar /u01/$FMW_JAR -silent -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="WebLogic Server" && \
    rm /u01/$FMW_JAR /u01/$FMW_PKG /u01/install.file && \
    rm -rf /u01/oracle/cfgtoollogs

# Final image stage
FROM oracle/serverjre:8
ENV ORACLE_HOME=/u01/oracle \
    VOLUME_DIR=/u01/oracle/user_projects \
    SCRIPT_FILE=/u01/oracle/container-scripts/* \
    HEALTH_SCRIPT_FILE=/u01/oracle/container-scripts/get_healthcheck_url.sh \
    DOMAIN_NAME="${DOMAIN_NAME:-infra_domain}" \
    ADMIN_LISTEN_PORT="${ADMIN_LISTEN_PORT:-7001}" \
    ADMIN_NAME="${ADMIN_NAME:-AdminServer}" \
    ADMIN_HOST="${ADMIN_HOST:-InfraAdminContainer}" \
    ADMINISTRATION_PORT_ENABLED="${ADMINISTRATION_PORT_ENABLED:-true}" \
    ADMINISTRATION_PORT="${ADMINISTRATION_PORT:-9002}" \
    MANAGEDSERVER_PORT="${MANAGEDSERVER_PORT:-8001}" \
    MANAGED_NAME="${MANAGED_NAME:-infraServer1}" \
    MANAGED_SERVER_CONTAINER="${MANAGED_SERVER_CONTAINER:-false}" \
    RCUPREFIX="${RCUPREFIX:-INFRA01}" \
    PRODUCTION_MODE="${PRODUCTION_MODE:-prod}" \
    CONNECTION_STRING=${CONNECTION_STRING:-InfraDB:1521/InfraPDB1.us.oracle.com} \
    JAVA_OPTIONS="-Doracle.jdbc.fanEnabled=false -Dweblogic.StdoutDebugEnabled=false" \
    PATH=$PATH:/usr/java/default/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts

RUN mkdir -p /u01 && \
    useradd -b /u01 -d /u01/oracle -m -s /bin/bash oracle && \
    chmod a+xr /u01 && chown oracle:oracle /u01 && \
    mkdir -p $VOLUME_DIR && chown oracle:oracle /u01 $VOLUME_DIR && \
    mkdir -p /u01/oracle/container-scripts && \
    yum install -y libaio && \
    rm -rf /var/cache/yum


# Copy packages and scripts
# -------------------------
COPY container-scripts/* /u01/oracle/container-scripts/

COPY --from=builder --chown=oracle:oracle /u01 /u01
RUN chmod +xr $SCRIPT_FILE

USER oracle
HEALTHCHECK --start-period=4m --interval=1m CMD curl -k -s --fail `$HEALTH_SCRIPT_FILE` || exit 1
WORKDIR ${ORACLE_HOME}
CMD ["/u01/oracle/container-scripts/createOrStartInfraDomain.sh"]
