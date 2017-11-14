#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# http://oss.oracle.com/licenses/upl.
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
FROM oracle/fmw-infrastructure:12.2.1.3
#
# Maintainer
# ----------
MAINTAINER Prashanth Nagaraja <prashanth.nagaraja@oracle.com>
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
RUN  yum install -y hostname &&    \
     cd /u01 && chmod 755 *.jar && \
     chmod a+xr /u01/oracle/dockertools/*.*
#
USER oracle
COPY install/* /u01/
RUN cd /u01 && \
  $JAVA_HOME/bin/java -jar $FMW_JAR1 -silent -responseFile /u01/soasuite.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME && \
  $JAVA_HOME/bin/java -jar $FMW_JAR2 -silent -responseFile /u01/soasuite.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="Service Bus" && \
  rm -fr /u01/*.jar /u01/*.response /u01/*.loc

#
# Define default command to start bash.
#
WORKDIR $ORACLE_HOME
CMD ["/u01/oracle/dockertools/createDomainAndStart.sh"]
