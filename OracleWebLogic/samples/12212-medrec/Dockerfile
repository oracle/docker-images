# LICENSE UPL 1.0
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic image by installing the Supplemental package of WebLogic which 
# includes extra samples of Java EE, Coherence applications, and Multitenant domains. 
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) fmw_12.2.1.2.0_wls_supplemental_quick_Disk1_1of1.zip
#     Download the Developer Quick installer from http://www.oracle.com/technetwork/middleware/weblogic/downloads/wls-for-dev-1703574.html 
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ sudo docker build -t 12212-medrec .
#

# Pull base image
# ---------------
FROM oracle/weblogic:12.2.1.2-developer

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV FMW_PKG="fmw_12.2.1.2.0_wls_supplemental_quick_Disk1_1of1.zip" \
    FMW_JAR="fmw_12.2.1.2.0_wls_supplemental_quick.jar" \
    MW_HOME="$ORACLE_HOME" \ 
    PATH="$ORACLE_HOME/wlserver/server/bin:$ORACLE_HOME/wlserver/../oracle_common/modules/org.apache.ant_1.9.2/bin:$JAVA_HOME/jre/bin:$JAVA_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$ORACLE_HOME/oracle_common/common/bin:$ORACLE_HOME/wlserver/common/bin:$ORACLE_HOME/user_projects/domains/medrec/bin:$ORACLE_HOME/wlserver/samples/server/medrec/:$ORACLE_HOME/wlserver/samples/server/:$ORACLE_HOME/wlserver/../oracle_common/modules/org.apache.maven_3.2.5/bin"

# Copy supplemental package and scripts
# --------------------------------
COPY $FMW_PKG /u01/
USER root
COPY startSample.sh  /u01/oracle/
RUN chmod +xr /u01/oracle/startSample.sh 

# Installation of Supplemental Quick Installer 
# --------------------------------------------
USER oracle
RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$FMW_PKG && cd - && \
    $JAVA_HOME/bin/java -jar /u01/$FMW_JAR  ORACLE_HOME=$ORACLE_HOME && \
    echo $USER && \
    mv /u01/oracle/startSample.sh /u01/oracle/wlserver/samples/server/  && \
    rm /u01/$FMW_PKG /u01/$FMW_JAR

USER root 
RUN chmod +xr /u01/oracle/wlserver/samples/server/*.sh

WORKDIR $ORACLE_HOME/wlserver/samples/server

EXPOSE 7011

CMD ["startSample.sh"]
