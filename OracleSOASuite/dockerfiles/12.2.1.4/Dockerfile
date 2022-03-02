#
# Copyright (c) 2017, 2022, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle SOA Suite
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# See soasuite.download file in the install directory
# Also see soapatches.download file in the patches directory
#
# Pull base image
# ---------------
FROM oracle/fmw-infrastructure:12.2.1.4.0 as builder

#
# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
USER root
ENV FMW_JAR1=fmw_12.2.1.4.0_soa.jar \
    FMW_JAR2=fmw_12.2.1.4.0_osb.jar \
    FMW_JAR3=fmw_12.2.1.4.0_b2bhealthcare.jar \
    OPATCH_PATCH_DIR="${OPATCH_PATCH_DIR:-/u01/opatch_patch}"  

#
# Copy installers and patches for install
# -------------------------------------------
ADD  $FMW_JAR1 $FMW_JAR2 $FMW_JAR3 /u01/
RUN mkdir /u01/patches  ${OPATCH_PATCH_DIR} && \
    chown oracle:root -R /u01
COPY patches/* /u01/patches/ 
COPY opatch_patch/* ${OPATCH_PATCH_DIR}/ 
COPY container-scripts/* /u01/oracle/container-scripts/
RUN  cd /u01 && chmod 755 *.jar && \
     chmod +xr /u01/oracle/container-scripts/*.*

#
# Copy files and packages for install
# -----------------------------------
USER oracle
COPY install/* /u01/
RUN cd /u01 && \
  $JAVA_HOME/bin/java -jar $FMW_JAR1 -silent -responseFile /u01/soasuite.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME && \
  $JAVA_HOME/bin/java -jar $FMW_JAR2 -silent -responseFile /u01/osb.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="Service Bus" && \
  $JAVA_HOME/bin/java -jar $FMW_JAR3 -silent -responseFile /u01/b2b.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="B2B" && \
  rm -fr /u01/*.jar /u01/*.response

#
# Apply OPatch patch
# ------------------
#
RUN opatchzip=`ls ${OPATCH_PATCH_DIR}/p*.zip 2>/dev/null`; \
    if [ ! -z "$opatchzip" ]; then \
      cd ${OPATCH_PATCH_DIR};  \
      echo -e "\nApplying the below OPatch patch present in ${OPATCH_PATCH_DIR} directory."; \
      ls p*.zip; \
      echo -e ""; \
      echo "Extracting patch: ${opatchzip}"; \
      $JAVA_HOME/bin/jar xf ${opatchzip} ; \
      $JAVA_HOME/bin/java -jar ${OPATCH_PATCH_DIR}/6880880/opatch_generic.jar -silent oracle_home=$ORACLE_HOME; \
      if [ $? -ne 0 ]; then \
        echo "Applying patch to opatch Failed" ; \
        exit 1 ; \
      fi; \
      rm -rf ${OPATCH_PATCH_DIR}; \
      echo "OPatch patch applied successfully."; \
    fi

#
# Apply SOA Patches
# -----------------
RUN export OPATCH_NO_FUSER=TRUE && patchzips=`ls /u01/patches/p*.zip 2>/dev/null`; \
    if [ ! -z "$patchzips" ]; then \
      cd /u01/patches;  \
      echo -e "\nBelow patches present in patches directory. Applying these patches:"; \
      ls p*.zip; \
      echo -e ""; \
      for filename in `ls p*.zip`; do echo "Extracting patch: ${filename}"; $JAVA_HOME/bin/jar xf ${filename}; done; \
      rm -f /u01/patches/p*.zip; \
      $ORACLE_HOME/OPatch/opatch napply -silent -oh $ORACLE_HOME -jre $JAVA_HOME -invPtrLoc /u01/oraInst.loc -phBaseDir /u01/patches; \
      $ORACLE_HOME/OPatch/opatch util cleanup -silent; \
      rm -rf /u01/patches /u01/oracle/cfgtoollogs/opatch/*; \
      echo -e "\nPatches applied in SOA oracle home are:"; \
      cd $ORACLE_HOME/OPatch; \
      $ORACLE_HOME/OPatch/opatch lspatches; \
    else \
      echo -e "\nNo patches present in patches directory. Skipping patch application."; \
    fi && \
    # Extract XEngine tar gz if present
    if [ -f "${ORACLE_HOME}/soa/soa/thirdparty/edifecs" ] && [  -f "XEngine_8_4_1_23.tar.gz" ]; then \
        cd $ORACLE_HOME/soa/soa/thirdparty/edifecs && \
        tar -zxvf  XEngine_8_4_1_23.tar.gz \
    else \
        echo -e "\nNo XEngine_8_4_1_23.tar.gz present in ${ORACLE_HOME}/soa/soa/thirdparty/edifecs directory. Skipping untar."; \
    fi && \
    # zip as few log files grow larger when patches are installed.
    if ls /u01/oracle/cfgtoollogs/opatch/*.log; then \
        gzip /u01/oracle/cfgtoollogs/opatch/*.log; \
    fi
#
# Rebuild from base image
# -----------------------
FROM oracle/fmw-infrastructure:12.2.1.4.0

#
# Maintainer
# ----------
LABEL maintainer="Sambasiva Battagiri <sambasiva.battagiri@oracle.com>"

#
# Install the required packages
# -----------------------------
USER root
ENV PATH=$PATH:/u01/oracle/container-scripts:/u01/oracle/oracle_common/modules/thirdparty/org.apache.ant/1.10.5.0.0/apache-ant-1.10.5/bin
RUN yum install -y hostname && \
    rm -rf /var/cache/yum

COPY --from=builder --chown=oracle:root /u01 /u01

#
# Define default command to start bash.
# 
USER oracle
HEALTHCHECK --start-period=5m --interval=1m CMD curl -k -s --fail `$HEALTH_SCRIPT_FILE` || exit 1
WORKDIR $ORACLE_HOME
CMD ["/u01/oracle/container-scripts/createDomainAndStart.sh"]

