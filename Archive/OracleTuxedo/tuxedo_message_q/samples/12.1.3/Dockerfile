# Pull Tuxedo base image
FROM oracle/tuxedo:12.1.3

MAINTAINER Judy Liu<judy.liu@oracle.com>

# Common environment variables required for this build (do NOT change)
# --------------------------------------------------------------------
ENV ORACLE_HOME=/u01/oracle/tuxHome \
    JAVA_HOME=/usr/java/default \
    PATH=/usr/java/default/bin:$PATH \
    TUXRP_PKG=p*_121300_Linux-x86-64.zip \
    TMQ_PKG=otmq121300_64_Linux_x86.zip

# Copy packages
# -------------
USER root
COPY tuxedotmq12.1.3.rsp $TUXRP_PKG $TMQ_PKG oraInst.loc init.sh /u01/
RUN  if [ "`/bin/ls -l /u01/$TUXRP_PKG|cut -c8`" != r ];then \
         chmod a+r /u01/$TUXRP_PKG; \
     fi  && \
     mv /u01/init.sh /u01/oracle/init.sh && \
     mv /u01/oraInst.loc /etc/ && \
     chown oracle:oracle -R /u01 && \
     chmod +x /u01/oracle/init.sh

# Apply Rolling Patch
# ------------------------------------------------------------
#     ln -s $JAVA_HOME tuxHome/jdk && \
USER oracle
RUN cd /u01/oracle && \
      ln -s $JAVA_HOME tuxHome/jdk && \
      mkdir tmp && cd tmp && \
      jar xf /u01/$TUXRP_PKG && \
      tux_patch=`find . -name *.zip` && \
      /u01/oracle/tuxHome/OPatch/opatch apply $tux_patch && \
      cd && rm -rf tmp /u01/$TUXRP_PKG 

# Install Tuxedo TMQ
# ------------------------------------------------------------
RUN cd /u01 && \
      jar xf $TMQ_PKG && \
      cd /u01/Disk1/install && \
      chmod -R +x * && \
      ./runInstaller -responseFile /u01/tuxedotmq12.1.3.rsp -silent -waitforcompletion && \
      rm -rf /u01/Disk1 \
             /u01/tuxedotmq12.1.3.rsp \
             /u01/$TMQ_PKG

ENV ORACLE_HOME=/u01/oracle/tuxHome \
    TUXDIR=/u01/oracle/tuxHome/tuxedo12.1.3.0.0

USER oracle
WORKDIR /u01/oracle

# Define ENTRYPOINT. 
ENTRYPOINT ["/u01/oracle/init.sh"]
