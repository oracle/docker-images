# LICENSE CDDL 1.0 + GPL 2.0
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
# (1) fmw_12.2.1.0.0_wls_supplemental_quick.jar
#     Download the Developer Quick installer from http://www.oracle.com/technetwork/middleware/weblogic/downloads/wls-for-dev-1703574.html 
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ sudo docker build -t 1221-medrec .
#

# Pull base image
# ---------------
FROM oracle/weblogic:12.2.1-developer

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV FMW_PKG="fmw_12.2.1.0.0_wls_supplemental_quick_Disk1_1of1.zip" \
    MW_HOME="$ORACLE_HOME" \
    ANT_OPTIONS="-Djava.security.egd=file:/dev/./urandom -Xms512m -Xmx1024m -XX:MaxPermSize=2048m" \
    EXAMPLES_HOME="/u01/oracle/wlserver/samples/server" \
    CLASSPATH="$JAVA_HOME/lib/tools.jar:$ORACLE_HOME/wlserver/modules/features/wlst.wls.classpath.jar" \
    PATH="$ORACLE_HOME/wlserver/server/bin:$ORACLE_HOME/wlserver/../oracle_common/modules/org.apache.ant_1.9.2/bin:$JAVA_HOME/jre/bin:$JAVA_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$ORACLE_HOME/oracle_common/common/bin:$ORACLE_HOME/wlserver/common/bin:$ORACLE_HOME/user_projects/domains/medrec/bin:$ORACLE_HOME/wlserver/samples/server/medrec/:$ORACLE_HOME/wlserver/../oracle_common/modules/org.apache.maven_3.2.5/bin"

# Copy supplemental package and scripts
# --------------------------------
COPY $FMW_PKG weblogic.properties startSample.sh ./

# Installation of Supplemental Quick Installer 
# --------------------------------------------
RUN jar xvf $FMW_PKG && \
    java -jar $(ls -1 *.jar) ORACLE_HOME=$ORACLE_HOME && \
    mkdir -p /u01/oracle/wlserver/samples/server/medrec/ && \
    mv weblogic.properties startSample.sh /u01/oracle/wlserver/samples/server/medrec/ && \ 
    rm $FMW_PKG $(ls -1 *.jar)

WORKDIR $ORACLE_HOME/wlserver/samples/server/medrec

ENTRYPOINT ["./startSample.sh"]

EXPOSE 7001

CMD ["single.server.sample"]
