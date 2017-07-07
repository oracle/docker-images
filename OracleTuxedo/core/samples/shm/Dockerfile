# Pull Tuxedo base image
FROM oracle/tuxedo:12.2.2

MAINTAINER Judy Liu<judy.liu@oracle.com>
COPY simpapp_runme.sh /u01/oracle/

USER root
RUN chown oracle:oracle -R /u01/oracle/ && \
    chmod +x /u01/oracle/simpapp_runme.sh

USER oracle
WORKDIR /u01/oracle

# Define ENTRYPOINT. 
ENTRYPOINT ["bash","/u01/oracle/simpapp_runme.sh"]

