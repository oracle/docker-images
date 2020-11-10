# Copyright (c) 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: OIG Development 
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle IDM 12.2.1.4 Quick Start
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) fmw_12.2.1.4.0_idm_generic.jar  
#
# Pull base image
# ---------------
FROM fmw-soa:12.2.1.4.0 as base
#
#
# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV FMW_JAR=fmw_12.2.1.4.0_idm_generic.jar \
#ENV FMW_JAR=fmw_12.2.1.4.0_idmquickstart_generic.jar \
    ORACLE_HOME=/u01/oracle \
    PATCH_DIR=/tmp/patches \
    OPATCH_PATCH_DIR=/tmp/opatch \
    OPATCH_NO_FUSER=true \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
    PATH=$PATH:$JAVA_HOME/bin:$ORACLE_HOME/oracle_common/common/bin \
    DOMAIN_NAME="${DOMAIN_NAME:-base_domain}" \
    DOMAIN_ROOT="${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}" \
    DOMAIN_HOME="${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}"/"${DOMAIN_NAME:-base_domain}" \
    ADMIN_PORT="${ADMIN_PORT:-7001}" \
    SOA_PORT="${SOA_PORT:-8001}" \
    OIM_PORT="${OIM_PORT:-14000}" \
    OIM_SSL_PORT="${OIM_SSL_PORT:-14002}" \
    PATH=$PATH:/u01/oracle \
    DOMAIN_TYPE="oim"    

FROM base as builder
 
USER root
RUN mkdir -p /u01 && \
    mkdir -p /u01/oracle/dockertools && \
    mkdir ${PATCH_DIR} && \
    mkdir ${OPATCH_PATCH_DIR} && \
    chown -R oracle:oracle /u01 && \
    chown -R oracle:oracle ${PATCH_DIR} && \
    chown -R oracle:oracle ${OPATCH_PATCH_DIR}  

#
# Copy files and packages for install
# -----------------------------------
COPY *.response oraInst.loc fmw_12.2.1.4.0_idm_generic* /u01/
COPY container-scripts/* /u01/oracle/dockertools/
COPY --chown=oracle:oracle Dockerfile patches/* ${PATCH_DIR}/
COPY --chown=oracle:oracle Dockerfile opatch_patch/* ${OPATCH_PATCH_DIR}/
RUN chmod a+xr /u01/oracle/dockertools/*.*

USER oracle
RUN cd /u01 && \
 $JAVA_HOME/bin/java -jar /u01/$FMW_JAR -silent -responseFile /u01/idmqs.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME && \
 rm -f /u01/*.jar /u01/oraInst.loc /u01/*.response \
 rm -f ${OPATCH_PATCH_DIR}/Dockerfile && \
 rm -f ${PATCH_DIR}/Dockerfile

#
# Apply patch to OPatch
#
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
        echo "opatch apply Failed"; \
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
      echo -e "\nPatches applied in OIG Oracle Home are:"; \
      cd $ORACLE_HOME/OPatch; \
      $ORACLE_HOME/OPatch/opatch lspatches; \
    else \
      echo -e "\nNo patches present in patches directory. Skipping patch application."; \
    fi
    
RUN rm -rf /u01/oracle/idm/server/ConnectorDefaultDirectory && \
    ln -s  /u01/oracle/user_projects/domains/ConnectorDefaultDirectory /u01/oracle/idm/server/ConnectorDefaultDirectory && \
    if $ORACLE_HOME/OPatch/opatch lsinventory  -oh $ORACLE_HOME -jre $JAVA_HOME | grep -q 23855729; then \
     echo "Ready End Point already Configured."; \
    else \
      sed -i 's|true</ready|false</ready|g' /u01/oracle/idm/server/apps/oim.ear/META-INF/weblogic-application.xml; \
    fi

FROM base as FINAL_BUILD

COPY --from=builder --chown=oracle:oracle /u01 /u01

USER oracle
WORKDIR $ORACLE_HOME

#
# Define default command to start bash.
CMD ["/u01/oracle/dockertools/createDomainAndStart.sh"]
