
# Pull base image
# ---------------
FROM oracle/weblogic:12.2.1.3-developer

MAINTAINER Lily He <lily.he@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV MW_HOME="$ORACLE_HOME" \
    PATH="$PATH:$ORACLE_HOME/wlserver/samples/server/:$ORACLE_HOME/wlserver/server/bin:$ORACLE_HOME/wlserver/../oracle_common/modules/org.apache.ant_1.9.2/bin" \
    WLST="$ORACLE_HOME/oracle_common/common/bin/wlst.sh" \
    DOMAIN_NAME=wlsdomain \
    SAMPLE_DOMAIN_HOME=/u01/wlsdomain \
    ADMIN_PORT=8001

USER root
# Copy scripts and install python http lib
# --------------------------------
COPY container-scripts/ /u01/oracle/
RUN chmod +x /u01/oracle/*.sh /u01/oracle/*.py

# install requests module of python since we need it to call REST api
RUN yum -y install python-requests && \
    rm -rf /var/cache/yum

USER oracle
WORKDIR $SAMPLE_DOMAIN_HOME
