# Pull Tuxedo base image
FROM oracle/tuxedo:12.2.2

MAINTAINER Judy Liu<judy.liu@oracle.com>
COPY jolt_runme.sh /u01/oracle
COPY container-scripts/* /u01/oracle/jolt/

USER root
RUN chown oracle:oracle -R /u01/oracle/ && \
    chmod +x /u01/oracle/jolt_runme.sh

ENV JSL_PORT=1304 \
    JSH_PORT1=1305 \
    JSH_PORT2=1306 \
    JSH_PORT3=1307 \
    JSH_PORT4=1308 \
    JSH_PORT5=1309 

EXPOSE $JSL_PORT $JSH_PORT1 $JSH_PORT2 $JSH_PORT3 $JSH_PORT4 $JSH_PORT5

WORKDIR /u01/oracle

# Define ENTRYPOINT.
ENTRYPOINT ["/u01/oracle/jolt_runme.sh"]

