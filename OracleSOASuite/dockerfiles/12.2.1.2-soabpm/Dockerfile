# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle SOA Suite 12.2.1.2
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# See soasuite.download file in this directory
#
# Pull base image
# ---------------
FROM oracle/fmw-infrastructure:12.2.1.2
#
# Maintainer
# ----------
MAINTAINER Prashanth Nagaraja <prashanth.nagaraja@oracle.com>
#
# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
USER root
ENV FMW_JAR1=fmw_12.2.1.2.0_soa.jar \
    FMW_JAR2=fmw_12.2.1.2.0_osb.jar

#
# Copy files and packages for install
# -----------------------------------
ADD $FMW_JAR1 $FMW_JAR2 /u01/
COPY container-scripts/* /u01/oracle/dockertools/
RUN cd /u01 && chmod 755 *.jar && chmod a+xr /u01/oracle/dockertools/*.*
#
USER oracle
COPY *.response oraInst.loc /u01/
RUN cd /u01 && \
  $JAVA_HOME/bin/java -jar $FMW_JAR1 -silent -responseFile /u01/soasuite.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME && \
  $JAVA_HOME/bin/java -jar $FMW_JAR2 -silent -responseFile /u01/soasuite.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="Service Bus" && \
  rm -f /u01/*.jar /u01/oraInst.loc /u01/*.response

#
# Define default command to start bash.
#
WORKDIR $ORACLE_HOME
CMD ["/u01/oracle/dockertools/createDomainAndStart.sh"]
