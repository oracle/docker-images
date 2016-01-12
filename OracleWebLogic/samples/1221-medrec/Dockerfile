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
ENV WLS_PKG fmw_12.2.1.0.0_wls_supplemental_quick.jar 
ENV JAVA_HOME /usr/java/default
ENV ORACLE_HOME /u01/oracle
ENV MW_HOME $ORACLE_HOME
ENV CONFIG_JVM_ARGS -Djava.security.egd=file:/dev/./urandom
ENV USER_MEM_ARGS -Xms256m -Xmx512m -XX:MaxPermSize=2048m
ENV _JAVA_OPTIONS -XX:+PrintCommandLineFlags -Djava.security.egd=file:/dev/./urandom

# Copy supplemental package and scripts
# --------------------------------
COPY $WLS_PKG /u01/

# Installation of Supplemental Quick Installer 
# --------------------------------------------
USER oracle
WORKDIR /u01
RUN java -jar $WLS_PKG ORACLE_HOME=$ORACLE_HOME && \
    rm /u01/$WLS_PKG

COPY weblogic.properties /u01/oracle/wlserver/samples/server/medrec/
COPY startSample.sh /u01/oracle/wlserver/samples/server/medrec/

ENV EXAMPLES_HOME /u01/oracle/wlserver/samples/server
ENV CLASSPATH $JAVA_HOME/lib/tools.jar:$ORACLE_HOME/wlserver/modules/features/wlst.wls.classpath.jar
ENV PATH $ORACLE_HOME/wlserver/server/bin:$ORACLE_HOME/wlserver/../oracle_common/modules/org.apache.ant_1.9.2/bin:$JAVA_HOME/jre/bin:$JAVA_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$ORACLE_HOME/oracle_common/common/bin:$ORACLE_HOME/wlserver/common/bin:$ORACLE_HOME/user_projects/domains/medrec/bin:$ORACLE_HOME/wlserver/samples/server/medrec/:$ORACLE_HOME/wlserver/../oracle_common/modules/org.apache.maven_3.2.5/bin

WORKDIR $ORACLE_HOME/wlserver/samples/server/medrec

ENTRYPOINT ["./startSample.sh"]

CMD ["single.server.sample"]
