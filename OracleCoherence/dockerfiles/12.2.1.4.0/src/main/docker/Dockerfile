# Copyright 2019, Oracle Corporation and/or its affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Coherence 12.2.1 Quick Install Distribution
#
# REQUIRED BASE IMAGE TO BUILD THIS IMAGE
# ---------------------------------------
# This Dockerfile requires the base image oracle/serverjre:8
# (see https://github.com/oracle/docker-images/tree/master/OracleJava)
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) fmw_12.2.1.4.0_coherence_quick_Disk1_1of1.zip
#
#     Download the Quick installer from https://www.oracle.com/middleware/technologies/coherence-downloads.html
#
# (2) Jersey and Jackson libraries for Coherence Management over REST and Coherence Metrics
#
#     Use Maven to pull the dependent libraries
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Place fmw_12.2.1.4.0_coherence_quick_Disk1_1of1.zip in the same directory as this Dockerfile
#
# From the directory with this project's Maven pom.xml run:
#      $ mvn clean install
#

# Pull base image
# ---------------
FROM oracle/serverjre:8 AS builder

# Maintainer
# ----------
LABEL maintainer="patrick.fry@oracle.com"

# Environment variables required for this build (do NOT change)
ENV FMW_PKG=fmw_12.2.1.4.0_coherence_quick_Disk1_1of1.zip \
    FMW_JAR=fmw_12.2.1.4.0_coherence_quick.jar \
    ORACLE_HOME=/u01/oracle/oracle_home \
    PATH=$PATH:/usr/java/default/bin \
    CONFIG_JVM_ARGS="-Djava.security.egd=file:/dev/./urandom"

RUN mkdir -p /u01 && \
    useradd -b /u01 -d /u01/oracle -m -s /bin/bash -u 1000 -g 0 oracle

# Copy files required to build this image
COPY $FMW_PKG install.file oraInst.loc /u01/

RUN chmod a+xr /u01 && \
    chown oracle:oracle -R /u01

USER oracle

# Install Coherence
RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$FMW_PKG && cd - && \
    $JAVA_HOME/bin/java -jar /u01/$FMW_JAR -silent -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME && \
    rm /u01/$FMW_JAR /u01/$FMW_PKG /u01/oraInst.loc /u01/install.file

# ---------------------------------------------------------------------------
# Final stage image containing the installed Oracle Home
FROM oracle/serverjre:8

ENV ORACLE_HOME=/u01/oracle/oracle_home \
    PATH=$PATH:/usr/java/default/bin:/u01/oracle/oracle_home/oracle_common/common/bin \
    CONFIG_JVM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
    COHERENCE_HOME=/u01/oracle/oracle_home/coherence \
    DEPENDENCY_MODULES=/u01/coherence/thirdparty/lib

# Create the oracle user with the uid 1000
# Allow the start script to dynamically modify the /etc/passwd file when
# running in environments that create a dynamic user
# see: https://docs.okd.io/latest/creating_images/guidelines.html
RUN mkdir -p /u01 && \
    mkdir -p /logs && \
    useradd -b /u01 -d /u01/oracle -m -s /bin/bash -u 1000 -g 0 oracle &&\
    chmod g=u /etc/passwd

COPY --from=builder /u01/oracle    /u01/oracle
COPY start.sh                      /start.sh
COPY extend-cache-config.xml       $COHERENCE_HOME/conf/extend-cache-config.xml
COPY logging.properties            $COHERENCE_HOME/conf/logging.properties
COPY coherence/thirdparty/lib/     $DEPENDENCY_MODULES/

# The directories created below are created with the owner oracle and the group 0 (root)
# This ensures that the image is compatible with OpenShift which runs containers with a
# random user that is a member of the root group regardless of the user configured in
# this Dockerfile.
# see: https://docs.okd.io/latest/creating_images/guidelines.html
RUN chgrp -R 0 /u01 && \
    chmod -R g=u /u01 && \
    chmod 755 /start.sh && \
    chgrp -R 0 /start.sh && \
    chmod -R g=u /start.sh && \
    chgrp -R 0 /logs && \
    chmod -R g=u /logs

# The oracle user was added with the uid 1000. We use the uid here rather than the username
# for OpenShift best practice - see https://docs.okd.io/latest/creating_images/guidelines.html
USER 1000

ENTRYPOINT ["/start.sh"]
