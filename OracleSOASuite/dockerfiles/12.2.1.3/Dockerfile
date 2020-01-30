#
# Copyright (c) 2016, 2020 Oracle and/or its affiliates.
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
#
# Pull base image
# ---------------
FROM oracle/fmw-infrastructure:12.2.1.3 as builder

#
# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
USER root
ENV FMW_JAR1=fmw_12.2.1.3.0_soa.jar \
    FMW_JAR2=fmw_12.2.1.3.0_osb.jar

#
# Copy files and packages for install
# -----------------------------------
ADD  $FMW_JAR1 $FMW_JAR2 /u01/
COPY container-scripts/* /u01/oracle/dockertools/
RUN  cd /u01 && chmod 755 *.jar && \
     chmod +xr /u01/oracle/dockertools/*.*

#
# Install SOA
# -----------------------------------
USER oracle
COPY install/* /u01/
RUN cd /u01 && \
  $JAVA_HOME/bin/java -jar $FMW_JAR1 -silent -responseFile /u01/soasuite.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME && \
  $JAVA_HOME/bin/java -jar $FMW_JAR2 -silent -responseFile /u01/soasuite.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="Service Bus" && \
  rm -fr /u01/*.jar /u01/*.response

#
# Rebuild from base image
# -----------------------
FROM oracle/fmw-infrastructure:12.2.1.3

#
# Maintainer
# ----------
LABEL maintainer="Sambasiva Battagiri <sambasiva.battagiri@oracle.com>"

#
# Install the required packages
# -----------------------------
USER root
RUN yum install -y hostname ant && \
    rm -rf /var/cache/yum

COPY --from=builder --chown=oracle:oracle /u01 /u01

#
# Define default command to start bash.
#
USER oracle
WORKDIR $ORACLE_HOME
CMD ["/u01/oracle/dockertools/createDomainAndStart.sh"]
