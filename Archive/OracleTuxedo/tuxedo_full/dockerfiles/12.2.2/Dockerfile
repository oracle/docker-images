# Pull Tuxedo base image
FROM oracle/tuxedo:12.2.2

MAINTAINER Judy Liu<judy.liu@oracle.com>

# Common environment variables required for this build (do NOT change)
# --------------------------------------------------------------------
ENV ORACLE_HOME=/u01/oracle \
    JAVA_HOME=/usr/java/default \
    PATH=/usr/java/default/bin:$PATH \
    TUX_PKG=tuxedo122200_64_Linux_01_x86.zip

# Copy packages
# -------------
USER root
COPY tuxedo12.2.2.rsp $TUX_PKG oraInst.loc /u01/ 
RUN  mv /u01/oraInst.loc /etc/ && \
     chown oracle:oracle -R /u01
USER oracle

# Install Tuxedo
# ------------------------------------------------------------
RUN cd /u01 && \
      jar xf $TUX_PKG && \
      cd /u01/Disk1/install && \
      chmod -R +x * && \
      ./runInstaller.sh -responseFile /u01/tuxedo12.2.2.rsp -silent -waitforcompletion && \
      rm -rf /u01/Disk1 \
             /u01/tuxedo12.2.2.rsp \
             /u01/$TUX_PKG

ENV ORACLE_HOME=/u01/oracle/tuxHome
ENV TUXDIR /u01/oracle/tuxHome/tuxedo12.2.2.0.0

WORKDIR /u01/oracle

EXPOSE 7001 7002

# Define ENTRYPOINT. 
ENTRYPOINT ["/u01/oracle/init.sh"]
