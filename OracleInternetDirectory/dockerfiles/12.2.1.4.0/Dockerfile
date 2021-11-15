#  Copyright (c) 2021, Oracle and/or its affiliates.
#  Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#  Author: Pratyush Dash
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Internet Directory 12.2.1.4.0
# Base image of this dockerfile is the FMW Infrastructure 12.2.1.4.0 docker image.
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# See oid.download file in the install directory
# fmw_12.2.1.4.0_oid_linux64.bin & 
#
# Pull base image
# ---------------
FROM oracle/fmw-infrastructure:12.2.1.4.0 as base
#
#
# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV FMW_IDM_BIN=fmw_12.2.1.4.0_oid_linux64.bin \
    BASE_DIR=/u01 \
    ORACLE_HOME=/u01/oracle \
    PATCH_DIR=/tmp/patches \
    OPATCH_PATCH_DIR=/tmp/opatch \
    OPATCH_NO_FUSER=true \
    SCRIPT_DIR=/u01/oracle/dockertools \
    HEALTH_SCRIPT_FILE=/u01/oracle/dockertools/healthcheck_status.sh \
    PROPS_DIR=/u01/oracle/properties \
    USER_PROJECTS_DIR=/u01/oracle/user_projects \
    DOMAIN_ROOT=/u01/oracle/user_projects/domains \
    DOMAIN_NAME="${DOMAIN_NAME:-oid_domain}" \
    DOMAIN_HOME="${DOMAIN_ROOT}"/"${DOMAIN_NAME}" \
    ADMIN_USER="${ADMIN_USER:-}" \
    ADMIN_PASSWORD="${ADMIN_PASSWORD:-}" \
    SSL_WALLET_PASSWORD="${SSL_WALLET_PASSWORD:-}" \
    ORCL_ADMIN_PASSWORD="${ORCL_ADMIN_PASSWORD:-}" \
    CONNECTION_STRING="${CONNECTION_STRING:-OidDB:1521/orclpdb1.localdomain}" \
    CONTAINER_DIR=/u01/oracle/user_projects/container \
    ADMIN_LISTEN_HOST="${ADMIN_LISTEN_HOST:-}" \
    INSTANCE_HOST="${INSTANCE_HOST:-oidhost1}" \
    INSTANCE_NAME="${INSTANCE_NAME:-oid1}" \
    INSTANCE_TYPE="${INSTANCE_TYPE:-PRIMARY}" \
    ADMIN_NAME="${ADMIN_NAME:-AdminServer}" \
    ADMIN_LISTEN_PORT="${ADMIN_LISTEN_PORT:-7001}" \
    DOMAIN_TYPE="${DOMAIN_TYPE:-oid}" \
    LDAP_PORT="${LDAP_PORT:-3060}" \
    LDAPS_PORT="${LDAPS_PORT:-3131}" \
    RCUPREFIX=${RCUPREFIX:-OID01} \
    DB_USER=${DB_USER:-} \
    DB_PASSWORD=${DB_PASSWORD:-} \
    DB_SCHEMA_PASSWORD=${DB_SCHEMA_PASSWORD:-} \
    REALM_DN=${REALM_DN:-dc=us,dc=oracle,dc=com} \
    USER_MEM_ARGS=${USER_MEM_ARGS:-"-Djava.security.egd=file:/dev/./urandom"} \
    JAVA_OPTIONS="${JAVA_OPTIONS} -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" \
    PATH=$PATH:/usr/java/default/bin:$ORACLE_HOME/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/dockertools

#
# Creation of User, Directories and Installation of OS packages
# ----------------------------------------------------------------
USER root
RUN mkdir -p ${BASE_DIR} && \
    chmod a+xr ${BASE_DIR} && chown oracle:root ${BASE_DIR} && \
    mkdir -p ${USER_PROJECTS_DIR} && \
    chown -R oracle:root ${USER_PROJECTS_DIR} && chmod -R 775 ${USER_PROJECTS_DIR} && \
    mkdir -p ${CONTAINER_DIR} && \
    chown -R oracle:root ${CONTAINER_DIR} && chmod -R 775 ${CONTAINER_DIR} && \
    mkdir -p ${SCRIPT_DIR} && chown oracle:root ${SCRIPT_DIR} && \
    mkdir -p ${PROPS_DIR} && chown oracle:root ${PROPS_DIR} && \ 
    mkdir ${PATCH_DIR} && \
    mkdir ${OPATCH_PATCH_DIR} && \
    chown -R oracle:root ${BASE_DIR} && \
    chown -R oracle:root ${PATCH_DIR} && \
    chown -R oracle:root ${OPATCH_PATCH_DIR}

#
FROM base as builder
# Copy packages and scripts
# -------------------------
COPY --chown=oracle:root Dockerfile patches/* ${PATCH_DIR}/
COPY --chown=oracle:root Dockerfile opatch_patch/* ${OPATCH_PATCH_DIR}/  
COPY container-scripts/* ${SCRIPT_DIR}/
COPY install/* ${BASE_DIR}/
ADD  $FMW_IDM_BIN ${BASE_DIR}/

#
# Update Permissions for packages and scripts
# --------------------------------------------
RUN cd ${BASE_DIR} && chmod 755 *.bin && \
     chmod a+xr ${SCRIPT_DIR}/* && \
     chown -R oracle:root ${CONTAINER_DIR} && chmod -R 775 ${CONTAINER_DIR} && \
     chown oracle:root ${SCRIPT_DIR}/* && \
     yum install -y libaio hostname gcc procps numactl-libs gcc-c++ make && \
     rm -rf /var/cache/yum
# 
# Installation of IDM Binaries
# --------------------------------------------
USER oracle
WORKDIR ${ORACLE_HOME}
RUN cd ${BASE_DIR} && \
#install IDM in silent mode
 /u01/fmw_12.2.1.4.0_oid_linux64.bin -force -ignoreSysPrereqs -silent -responseFile ${BASE_DIR}/oid.response -invPtrLoc ${ORACLE_HOME}/oraInst.loc ORACLE_HOME=$ORACLE_HOME -jreLoc $JAVA_HOME && \
 rm -fr ${BASE_DIR}/*.bin ${BASE_DIR}/*.response && \
 rm -f ${OPATCH_PATCH_DIR}/Dockerfile && \
 rm -f ${PATCH_DIR}/Dockerfile

#
# Apply patch to OPatch
#
USER oracle
WORKDIR ${ORACLE_HOME} 
RUN opatchzip=`ls ${OPATCH_PATCH_DIR}/p*.zip 2>/dev/null`; \
    if [ ! -z "$opatchzip" ]; then \
      cd ${OPATCH_PATCH_DIR};  \
      echo -e "\nBelow patch present in opatch_patch directory. Applying this patch:" ; \
      ls p*.zip ; \
      echo -e "" ; \
      opatchfile=`ls p*.zip` ; \
      $JAVA_HOME/bin/jar xf $opatchfile ; \
      $JAVA_HOME/bin/java -jar ${OPATCH_PATCH_DIR}/6880880/opatch_generic.jar -silent oracle_home=$ORACLE_HOME; \
      if [ $? -ne 0 ]; then \
        echo "Applying patch to opatch Failed" ; \
        exit 1 ; \
      fi; \      
      cd /tmp; \
      rm  ${OPATCH_PATCH_DIR}/*.zip; \
      rm -r ${OPATCH_PATCH_DIR}/; \
    fi  
#
# Apply product patches 
#    
RUN patchzips=`ls ${PATCH_DIR}/p*.zip 2>/dev/null`; \
    if [ ! -z "$patchzips" ]; then \
      cd ${PATCH_DIR};  \
      echo -e "\nBelow patches present in patches directory. Applying these patches:"; \
      ls p*.zip; \
      echo -e ""; \
      $ORACLE_HOME/OPatch/opatch napply -silent -oh $ORACLE_HOME -jre $JAVA_HOME -phBaseDir ${PATCH_DIR}; \
      if [ $? -ne 0 ]; then \
        echo "opatch napply Failed"; \
        exit 1; \
      fi; \
      $ORACLE_HOME/OPatch/opatch util cleanup -silent -oh ${ORACLE_HOME}; \
      if [ $? -ne 0 ]; then \
        echo "opatch cleanup Failed"; \
        exit 1; \
      fi; \ 
      cd /tmp; \ 
      rm ${PATCH_DIR}/*.zip; \
      rm -r ${PATCH_DIR}/; \
      rm -rf ${ORACLE_HOME}/cfgtoollogs/opatch/*; \
      echo -e "\nPatches applied in OID oracle home are:"; \
      cd $ORACLE_HOME/OPatch; \
      $ORACLE_HOME/OPatch/opatch lspatches; \
    else \
      echo -e "\nNo patches present in patches directory. Skipping patch application."; \
    fi

FROM base as FINAL_BUILD
RUN yum install -y libaio hostname util-linux procps net-tools strace gdb && \
    rm -rf /var/cache/yum
COPY --from=builder --chown=oracle:root  $BASE_DIR $BASE_DIR 

# Define default command to start script.
USER oracle
HEALTHCHECK --start-period=5m --interval=2m CMD `$HEALTH_SCRIPT_FILE` > /dev/null || exit 1
WORKDIR $ORACLE_HOME
# Define default command to start bash.
CMD ["sh", "-c", "${SCRIPT_DIR}/createDomainAndStart.sh"]
