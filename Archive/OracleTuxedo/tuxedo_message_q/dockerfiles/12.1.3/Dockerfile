# Pull Tuxedo base image
FROM oracle/tuxedo:12.1.3

MAINTAINER Judy Liu<judy.liu@oracle.com>

# Common environment variables required for this build (do NOT change)
# --------------------------------------------------------------------
ENV ORACLE_HOME=/u01/oracle/tmqHome \
    JAVA_HOME=/usr/java/default \
    PATH=/usr/java/default/bin:$PATH \
    TMQ_PKG=otmq121300_64_Linux_x86.zip

# Copy packages
# -------------
USER root
COPY tuxedotmq12.1.3.rsp  $TMQ_PKG oraInst.loc init.sh /u01/
RUN  mv /u01/init.sh /u01/oracle/init.sh && \
     mv /u01/oraInst.loc /etc/ && \
     chown oracle:oracle -R /u01 && \
     chmod +x /u01/oracle/init.sh

# Install Tuxedo TMQ
# ------------------------------------------------------------
USER oracle
RUN cd /u01 && \
      jar xf $TMQ_PKG && \
      cd /u01/Disk1/install && \
      chmod -R +x * && \
      ./runInstaller -responseFile /u01/tuxedotmq12.1.3.rsp -silent -waitforcompletion && \
      rm -rf /u01/Disk1 \
             /u01/tuxedotmq12.1.3.rsp \
             /u01/$TMQ_PKG

ENV ORACLE_HOME=/u01/oracle/tmqHome \
    TUXDIR=/u01/oracle/tmqHome/tuxedo12.1.3.0.0

USER oracle
WORKDIR /u01/oracle

# Define ENTRYPOINT. 
ENTRYPOINT ["/u01/oracle/init.sh"]
