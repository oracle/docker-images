# LICENSE CDDL 1.0 + GPL 2.0
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This Dockerfile extends the Oracle WebLogic image by creating a sample domain.
#
#
# Util scripts are copied into the image enabling users to plug NodeManager 
# magically into the AdminServer running on another container as a Machine.
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
FROM oracle/weblogic:12.2.1-dev

# Maintainer
# ----------
MAINTAINER Monica Riccelli <monica.riccelli@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV WLS_PKG fmw_12.2.1.0.0_wls_supplemental_quick.jar 
ENV JAVA_HOME /usr/java/default
ENV ORACLE_HOME /u01/oracle/weblogic
ENV CONFIG_JVM_ARGS -Djava.security.egd=file:/dev/./urandom
ENV USER_MEM_ARGS -Xms256m -Xmx512m -XX:MaxPermSize=2048m
ENV _JAVA_OPTIONS -XX:+PrintCommandLineFlags -Djava.security.egd=file:/dev/./urandom

# Copy supplemental package
# --------------------------------
COPY $WLS_PKG /u01/

# Installation of Supplemental Quick Installer 
# --------------------------------------------
USER oracle
WORKDIR /u01
RUN java -jar $WLS_PKG ORACLE_HOME=$ORACLE_HOME && \
    rm /u01/$WLS_PKG

# Add files required to build this image
COPY container-scripts/* /u01/oracle/

# Set environment to create a Medrec domain and start a single server with a deployed medrec application
RUN echo "cp /u01/oracle/weblogic.properties /u01/oracle/weblogic/wlserver/samples/server/medrec/weblogic.properties" >> /u01/oracle/.bashrc && \
    echo "cp /u01/oracle/startSamples.sh /u01/oracle/weblogic/wlserver/samples/server/medrec/startSamples.sh" >> /u01/oracle/.bashrc && \
    echo ". /u01/oracle/weblogic/wlserver/samples/server/medrec/startSamples.sh" >> /u01/oracle/.bashrc

WORKDIR /u01/oracle/weblogic/wlserver/samples/server/medrec

ENV PATH $PATH:/u01/oracle/weblogic/wlserver/common/bin:/u01/oracle/weblogic/user_projects/domains/medrec/bin:/u01/oracle

# Define default command to start bash. 
CMD ["bash"]
