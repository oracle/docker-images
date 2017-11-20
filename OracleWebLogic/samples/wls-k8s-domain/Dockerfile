
# Pull base image
# ---------------
FROM weblogic-12.2.1.3-developer:latest

MAINTAINER Lily He <lily.he@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV MW_HOME="$ORACLE_HOME" \
    PATH="$ORACLE_HOME/wlserver/server/bin:$ORACLE_HOME/wlserver/../oracle_common/modules/org.apache.ant_1.9.2/bin:$JAVA_HOME/jre/bin:$JAVA_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$ORACLE_HOME/oracle_common/common/bin:$ORACLE_HOME/wlserver/common/bin:$ORACLE_HOME/wlserver/samples/server/" \
    WLST="$ORACLE_HOME/oracle_common/common/bin/wlst.sh" \
    DOMAIN_NAME=wlsdomain \
    SAMPLE_DOMAIN_HOME=/u01/wlsdomain \
    ADMIN_PORT=8001

user root
# Copy scripts and install python http lib
# --------------------------------
COPY container-scripts/ /u01/oracle/
RUN chmod +x /u01/oracle/*.sh /u01/oracle/*.py

# The following installation need internet access. If you are behind a proxy you may need to set http_proxy and https_proxy
# ENV http_proxy=foo \
#     https_proxy=foo

# install requests module of python since we need it to call REST api
RUN python /u01/oracle/get-pip.py && \
    pip install requests 

# unset proxy
# ENV https_proxy="" \
#     http_proxy=""

user oracle
WORKDIR $SAMPLE_DOMAIN_HOME
