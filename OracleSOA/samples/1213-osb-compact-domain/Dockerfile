# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ sudo docker build -t 1213-osb-compact-domain --build-arg ADMIN_PASSWORD=welcome1 .
#

# Pull base image
# ---------------
FROM oracle/soa:12.1.3-quickstart

# Maintainer
# ----------
MAINTAINER ToBeDefined

# WLS Configuration
# -------------------------------
ARG ADMIN_PASSWORD
ENV DOMAIN_NAME="base_domain" \
    DOMAIN_HOME="/u01/oracle/user_projects/domains/base_domain" \
    ADMIN_PORT="8001" \
    ADMIN_HOST="wlsadmin" \
    NM_PORT="5556" \
    MS_PORT="7001" \
    USER_MEM_ARGS="-Xms512m -Xmx1024m -XX:MaxPermSize=768m" \
    CONFIG_JVM_ARGS="-Dweblogic.security.SSL.ignoreHostnameVerification=true" \
    PATH=$PATH:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/user_projects/domains/base_domain/bin:/u01/oracle

# Add files required to build this image
USER root
COPY container-scripts/* /u01/oracle/
RUN chmod +x /u01/oracle/wlst
USER oracle
# Configuration of WLS Domain
WORKDIR /u01/oracle
RUN /u01/oracle/wlst /u01/oracle/create-osb-domain.py && \
    mkdir -p /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/security && \
    echo "username=weblogic" > /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/security/boot.properties && \
    echo "password=$ADMIN_PASSWORD" >> /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/security/boot.properties && \
    echo ". /u01/oracle/user_projects/domains/base_domain/bin/setDomainEnv.sh" >> /u01/oracle/.bashrc && \
    echo "export PATH=$PATH:/u01/oracle/wlserver/common/bin:/u01/oracle/user_projects/domains/base_domain/bin" >> /u01/oracle/.bashrc && \
    # cp /u01/oracle/commEnv.sh /u01/oracle/wlserver/common/bin/commEnv.sh && \
    rm /u01/oracle/create-osb-domain.py

# Expose Node Manager default port, and also default http/https ports for admin console
EXPOSE $NM_PORT $ADMIN_PORT $MS_PORT

WORKDIR $DOMAIN_HOME

# Define default command to start bash.
CMD ["startWebLogic.sh"]
