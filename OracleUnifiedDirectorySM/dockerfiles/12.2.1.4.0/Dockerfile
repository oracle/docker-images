#
# Copyright (c) 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Unified Directory Service Manager (OUDSM)
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# See oud.download file 
# Also see patches.download file in the patches directory

# ------------------------------------------------------------
# Pull base image
# ---------------
FROM oracle/fmw-infrastructure:12.2.1.4.0 as base

# Maintainer
# ----------
LABEL "maintainer"="Oracle Unified Directory team"                      \
      "provider"="Oracle"                                               \
      "issues"="https://github.com/oracle/docker-images/issues"         \
      "volume.user_projects"="/opt/oracle/user_projects"                \
      "port.admin"="7001"                                               \
      "port.adminSsl"="7002"                                            

#
# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV FMW_OUD_JAR=fmw_12.2.1.4.0_oud.jar \
    BASE_DIR=/u01 \
    ORACLE_HOME=/u01/oracle \
    SCRIPT_DIR=/u01/oracle/container-scripts \
    PROPS_DIR=/u01/oracle/properties \
    PATCHES_BASE_DIR=/tmp/oracle_patches \
    VOLUME_DIR=/u01/oracle/user_projects \
    DOMAIN_NAME="${DOMAIN_NAME:-base_domain}" \
    ADMIN_USER="${ADMIN_USER:-}" \
    ADMIN_PASS="${ADMIN_PASS:-}" \
    DOMAIN_ROOT="${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}" \
    DOMAIN_HOME="${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}"/"${DOMAIN_NAME:-base_domain}" \
    ADMIN_PORT="${ADMIN_PORT:-7001}" \
    ADMIN_SSL_PORT="${ADMIN_SSL_PORT:-7002}" \
    DOMAIN_TYPE="oudsm" \
    USER_MEM_ARGS=${USER_MEM_ARGS:-"-Djava.security.egd=file:/dev/./urandom"} \
    JAVA_OPTIONS="${JAVA_OPTIONS} -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" \
    PATH=$PATH:/usr/java/default/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts

#
# Creation of User, Directories and Installation of OS packages
# ----------------------------------------------------------------
USER root
RUN mkdir -p ${BASE_DIR} && \
    mkdir -p ${PATCHES_BASE_DIR}/opatch_patch && \
    mkdir -p ${PATCHES_BASE_DIR}/patches && \
    chmod a+xr ${BASE_DIR} && chown oracle:oracle ${BASE_DIR} && \
    chmod -R a+xr ${PATCHES_BASE_DIR} && chown -R oracle:oracle ${PATCHES_BASE_DIR} && \
    mkdir -p ${VOLUME_DIR} && \
    chown -R oracle:oracle ${VOLUME_DIR} && chmod -R 770 ${VOLUME_DIR} && \
    mkdir -p ${SCRIPT_DIR} && chown oracle:oracle ${SCRIPT_DIR} && \
    mkdir -p ${PROPS_DIR} && chown oracle:oracle ${PROPS_DIR} && \
    yum install -y libaio hostname && \
    rm -rf /var/cache/yum

# Builder Image for Installation of Binaries
# --------------------------------------------
FROM base as builder

# Copy install package, patches and scripts
# -----------------------------------------
COPY container-scripts/* ${SCRIPT_DIR}/
COPY install/* ${BASE_DIR}/
ADD  $FMW_OUD_JAR ${BASE_DIR}/
COPY --chown=oracle:oracle Dockerfile opatch_patch/* ${PATCHES_BASE_DIR}/opatch_patch/
COPY --chown=oracle:oracle Dockerfile patches/* ${PATCHES_BASE_DIR}/patches/

#
# Update Permissions for packages and scripts
# --------------------------------------------
RUN cd ${BASE_DIR} && chmod 755 *.jar && \
     chmod a+xr ${SCRIPT_DIR}/* && \
     chown oracle:oracle ${SCRIPT_DIR}/* && \
     chmod -R a+xr ${PATCHES_BASE_DIR} && \
     chown -R oracle:oracle ${PATCHES_BASE_DIR}

# 
# Installation of OUD Binaries
# --------------------------------------------
USER oracle
WORKDIR ${ORACLE_HOME}
#install OUD in silent mode
RUN $JAVA_HOME/bin/java -jar ${BASE_DIR}/$FMW_OUD_JAR -silent -responseFile ${BASE_DIR}/oud.response -invPtrLoc ${BASE_DIR}/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=${ORACLE_HOME} && \
  rm -fr ${BASE_DIR}/*.jar ${BASE_DIR}/*.response 

#
# Apply patch to OPatch
# ---------------------
RUN opatchzip=`ls ${PATCHES_BASE_DIR}/opatch_patch/p*.zip 2>/dev/null`; \
    if [ ! -z "$opatchzip" ]; then \
      cd ${PATCHES_BASE_DIR}/opatch_patch;  \
      echo -e "\nBelow patch present in opatch_patch directory. Applying this patch:" ; \
      ls p*.zip ; \
      echo -e "" ; \
      opatchfile=`ls p*.zip` ; \
      $JAVA_HOME/bin/jar xf $opatchfile ; \
      $JAVA_HOME/bin/java -jar ${PATCHES_BASE_DIR}/opatch_patch/6880880/opatch_generic.jar -silent oracle_home=$ORACLE_HOME; \
      if [ $? -ne 0 ]; then \
        echo "Applying patch to opatch Failed" ; \
        exit 1 ; \
      fi; \      
      cd /tmp; \
      rm  ${PATCHES_BASE_DIR}/opatch_patch/*.zip; \
      rm -r ${PATCHES_BASE_DIR}/opatch_patch/; \
    else \
      echo -e "\nNo OPatch patch present in opatch_patch directory. Skipping patch application."; \
    fi  

#
# Apply OUD Patches
# -----------------
RUN export OPATCH_NO_FUSER=TRUE && patchzips=`ls ${PATCHES_BASE_DIR}/patches/p*.zip 2>/dev/null`; \
    if [ ! -z "$patchzips" ]; then \
      cd ${PATCHES_BASE_DIR}/patches;  \
      echo -e "\nBelow patches present in patches directory. Applying these patches:"; \
      ls p*.zip; \
      echo -e ""; \
      for filename in `ls p*.zip`; do echo "Extracting patch: ${filename}"; $JAVA_HOME/bin/jar xf ${filename}; done; \
      rm -f ${PATCHES_BASE_DIR}/patches/p*.zip; \
      $ORACLE_HOME/OPatch/opatch napply -silent -oh $ORACLE_HOME -jre $JAVA_HOME -invPtrLoc ${BASE_DIR}/oraInst.loc -phBaseDir ${PATCHES_BASE_DIR}/patches; \
      $ORACLE_HOME/OPatch/opatch util cleanup -silent; \
      rm -rf ${PATCHES_BASE_DIR}/patches ${BASE_DIR}/oracle/cfgtoollogs/opatch/*; \
      echo -e "\nPatches applied in OUD oracle home are:"; \
      cd $ORACLE_HOME/OPatch; \
      $ORACLE_HOME/OPatch/opatch lspatches; \
    else \
      echo -e "\nNo patches present in patches directory. Skipping patch application."; \
    fi
#

# Final Image
# -------------
FROM base 

COPY --chown=oracle:oracle --from=builder $BASE_DIR $BASE_DIR
COPY --chown=oracle:oracle --from=builder $JAVA_HOME $JAVA_HOME

USER oracle
WORKDIR ${ORACLE_HOME}
# Define default command to start bash.
ENTRYPOINT ["sh", "-c", "${SCRIPT_DIR}/createDomainAndStart.sh"]
