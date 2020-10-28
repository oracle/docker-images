#
# Copyright (c) 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Unified Directory (OUD)
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# See oud.download file 
# Also see patches.download file in the patches directory

# From JDK as Base for the OUD Image
# ----------------------------------
FROM oracle/serverjre:8 as base

# Maintainer
# ----------
LABEL "maintainer"="Oracle Unified Directory team"                      \
      "provider"="Oracle"                                               \
      "issues"="https://github.com/oracle/docker-images/issues"         \
      "volume.user_projects"="/opt/oracle/user_projects"                \
      "port.adminldaps"="1444"                                          \
      "port.adminhttps"="1888"                                          \
      "port.ldap"="1389"                                                \
      "port.ldaps"="1636"                                               \
      "port.http"="1080"                                                \
      "port.https"="1081"                                               \
      "port.replication"="1898"                                         

#
# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV FMW_OUD_JAR=fmw_12.2.1.4.0_oud.jar \
    BASE_DIR=/u01 \
    ORACLE_HOME=/u01/oracle \
    SCRIPT_DIR=/u01/oracle/container-scripts \
    USER_PROJECTS_DIR=/u01/oracle/user_projects \
	PATCHES_BASE_DIR=/tmp/oracle_patches \
	OUD_INSTANCE_NAME=${OUD_INSTANCE_NAME:-asinst_1} \	
    PATH=$PATH:${JAVA_HOME}/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts

#
# Creation of User, Directories and Installation of OS packages
# ----------------------------------------------------------------
USER root
RUN mkdir -p ${BASE_DIR} && \
    mkdir -p ${PATCHES_BASE_DIR}/opatch_patch && \
    mkdir -p ${PATCHES_BASE_DIR}/patches && \
    useradd -b ${BASE_DIR} -d ${ORACLE_HOME} -m -s /bin/bash oracle && \
	chmod -R a+xr ${PATCHES_BASE_DIR} && chown -R oracle:oracle ${PATCHES_BASE_DIR} && \
    chmod -R a+xr ${BASE_DIR} && chown -R oracle:oracle ${BASE_DIR} && \
    mkdir -p ${USER_PROJECTS_DIR} && \
    chown -R oracle:oracle ${USER_PROJECTS_DIR} && chmod -R 770 ${USER_PROJECTS_DIR} && \
    mkdir -p ${SCRIPT_DIR} && chown oracle:oracle ${SCRIPT_DIR} && \
    yum install -y libaio hostname vi && \
    rm -rf /var/cache/yum

# Builder Image for Installation of Binaries
# --------------------------------------------
FROM base as builder

# Copy install jar, patches and scripts
# -------------------------------------
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
     chown -R oracle:oracle ${SCRIPT_DIR} && \
     chown -R oracle:oracle ${BASE_DIR} && \
     chown -R oracle:oracle ${PATCHES_BASE_DIR}

# 
# Installation of OUD Binaries
# --------------------------------------------
USER oracle
WORKDIR ${ORACLE_HOME}
# Install OUD in silent mode
RUN $JAVA_HOME/bin/java -jar ${BASE_DIR}/$FMW_OUD_JAR -silent -responseFile ${BASE_DIR}/oud.response -invPtrLoc ${BASE_DIR}/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=${ORACLE_HOME} && \
    rm -fr ${BASE_DIR}/*.jar ${BASE_DIR}/*.response && \
# Disabling Enpoint Identification for selected CLIs to allow connecting to OUD Instance with any hostname \
    echo "" >> ${ORACLE_HOME}/oud/config/java.properties && \
    echo "dsconfig.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
    echo "dsreplication.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
    echo "uninstall.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
    echo "status.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
    echo "import-ldif.online.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
    echo "manage-suffix.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
    echo "ldapmodify.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
    echo "ldapsearch.java-args=-client -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
	echo "start-ds.java-args=-server -Xms256m -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true" >> ${ORACLE_HOME}/oud/config/java.properties && \
    ${ORACLE_HOME}/oud/bin/dsjavaproperties

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
  
# run container health check
HEALTHCHECK --interval=1m --start-period=5m \
   CMD "${SCRIPT_DIR}/checkOUDInstance.sh" > /dev/null || exit 1
   
# Create and Start OUD Instance
CMD ["sh", "-c", "${SCRIPT_DIR}/createAndStartOUDInstance.sh"]
