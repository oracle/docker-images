#Copyright (c) 2021 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for OGG Veridata Infrastructure 12.2.1.4.0
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# The OGG Veridata Infrastructure image extends the Oracle FMW Infrastructure 12.2.1.4-191221 image, you must first build the Oracle FMW Infrastructure image.
# Run:
#      $ docker build -f Dockerfile -t oracle/oggvdt:12.2.1.4.0 .
#
# IMPORTANT
# ---------
# The resulting image of this Dockerfile contains a OGG Veridata Infrastructure.
#
# ----------------------------------------------------------------------------------------------

ARG FMW_VERSION=${FMW_VERSION}

FROM container-registry.oracle.com/middleware/fmw-infrastructure:${FMW_VERSION}

ARG VERIDATA_VERSION
ARG INSTALLER_VERSION
ARG INSTALLER
ARG PATCH_FILE
ARG OWNER_GROUP


# Maintainer
# ----------
#MAINTAINER Jonathan Fu <jonathan.fu@oracle.com> , Arnab Nandi <arnab.x.nandi@oracle.com>

LABEL maintainer="Jonathan Fu <jonathan.fu@oracle.com> , Arnab Nandi <arnab.x.nandi@oracle.com>"

#RUN echo  "FMW Version: $FMW_VERSION  OGG Veridata Version $VERIDATA_VERSION"


# Common environment variables required for this build
# ----------------------------------------------------
ENV VDT_PKG=${INSTALLER} \
    VDT_JAR=fmw_${INSTALLER_VERSION}_ogg*.jar \
    ORACLE_HOME=/u01/oracle \
    PATH=$PATH:/u01/oracle/oracle_common/common/bin:/u01/oracle/container-scripts \
    HEALTHCHECK_SCRIPT=/u01/oracle/container-scripts/healthCheck.sh \
    VERIDATA_ADMIN_SERVER="false" \
    VERIDATA_MANAGED_SERVER="false" \
    VERIDATA_AGENT="false" \
    DOMAIN_NAME="base_domain" \
    DOMAIN_ROOT="${DOMAIN_ROOT:-/u01/oracle/user_projects/domains}" \
    PATCH_FILE_LOCATION=/u01 \
    SERVER_START="False" \
    PATCH_FILE=${PATCH_FILE}



# Setup subdirectory for Veridata install package and container-scripts
# -----------------------------------------------------------------
RUN mkdir -p /u01 && \
    chmod a+xr /u01 && \
    export PATH=/usr/sbin:${PATH}


# Copy packages
# -------------
COPY $VDT_PKG install.file oraInst.loc /u01/

USER root
RUN useradd oracle ; exit 0

USER root
RUN  groupadd oracle ; exit 0

USER root
RUN chown ${OWNER_GROUP} -R /u01

# Install
# ------------------------------------------------------------

USER oracle
RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$VDT_PKG && cd - && \
    $JAVA_HOME/bin/java -jar /u01/$VDT_JAR -silent -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME  && \
    rm /u01/$VDT_JAR /u01/$VDT_PKG  && \
    rm -rf /u01/oracle/cfgtoollogs


#/u01/install.file

# Copy packages and scripts
# -------------------------
USER root
COPY container-scripts/* /u01/oracle/container-scripts/
COPY vdt.env /u01/oracle/
COPY vdtagent.env /u01/oracle/
COPY ${PATCH_FILE} /u01/oracle/
RUN chmod a+xr /u01/oracle/container-scripts/*.* &&\
    chmod a+xr /u01/oracle/${PATCH_FILE} && \
    mkdir $ORACLE_HOME/temp && \
    chown ${OWNER_GROUP} -R $ORACLE_HOME/temp && \
    chown ${OWNER_GROUP} -R $ORACLE_HOME

#USER root
#RUN echo -n 'y' | yum install unzip

#USER root
#RUN echo -n 'y' | yum install vim ; exit 0

USER oracle
RUN  /u01/oracle/container-scripts/applyRollbackPatch.sh

USER oracle
RUN rm /u01/oracle/$PATCH_FILE ; exit 0


USER oracle
HEALTHCHECK --start-period=5m --interval=2m CMD ${HEALTHCHECK_SCRIPT}
WORKDIR ${ORACLE_HOME}
#CMD ["/u01/oracle/container-scripts/createOrStartVdtDomain.sh"]
