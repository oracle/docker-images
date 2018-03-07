#
# Dockerfile template for Tuxedo ART 12.2.2
# 
# Pull base image
FROM oracle/tuxedo:12.2.2

MAINTAINER Judy Liu <judy.liu@oracle.com>

# Create the installation directory tree and user oracle with a password of oracle
USER root
RUN yum -y install perl perl-CPAN ksh mksh sudo make vim tar net-tools dos2unix tk tcl-devel tk-devel gtk2 expect libaio openssh-client rsync && yum -y clean all 

#Set environments
ENV ORACLE_HOME=/u01/oracle/tuxHome \
    PATH=/usr/java/default/bin:$PATH \
    TMPFILES=/tmp/files \
    ARTTM_PKG=art_tm122200_64_linux_x86_64.zip \
    ARTWKB_PKG=art_wb122200_64_linux_x86_64.zip

#Install Derby
ADD bin/derby.tar.gz /usr/java/default

#Install Eclipse
ADD bin/eclipse*.gz /u01/oracle

# Copy packages
# -------------
COPY bin/$ARTTM_PKG bin/$ARTWKB_PKG \
     tuxedoarttm12.2.2.rsp  tuxedoartwkb12.2.2.rsp init.sh \
     bin/p*.zip /u01/
RUN  mv /u01/init.sh /u01/oracle/init.sh && \
     chown oracle:oracle -R /u01 && \
     chmod +x /u01/oracle/init.sh

#Install Tuxedo ART Workbench and Tuxedo ART Test Manager
USER oracle
ENV ORACLE_HOME=/u01/oracle/tuxHome
RUN cd /u01 && \
      mkdir -p oraInventory && \
      jar xf $ARTWKB_PKG && \
      cd /u01/Disk1/install && \
      chmod -R +x * && \
      ./runInstaller.sh -responseFile /u01/tuxedoartwkb12.2.2.rsp -silent -waitforcompletion && \
      cd /u01 && \
      rm -rf /u01/Disk1 \
             /u01/tuxedoartwkb12.2.2.rsp \
             /u01/$ARTWKB_PKG && \
      jar xf $ARTTM_PKG && \
      cd /u01/Disk1/install && \
      chmod -R +x * && \
      ./runInstaller.sh -responseFile /u01/tuxedoarttm12.2.2.rsp -silent -waitforcompletion && \
      rm -rf /u01/Disk1 \
             /u01/tuxedoarttm12.2.2.rsp \
             /u01/$ARTTM_PKG 

# Install Tuxedo and ART Patches
RUN cd /u01/oracle && \
    ln -s $JAVA_HOME tuxHome/jdk && \
    for patch_file in `/bin/ls /u01/p*.zip`; do \
      if [ "`/bin/ls -l $patch_file|cut -c8`" != r ];then \
         chmod a+r $patch_file; \
      fi;  \
      cd /u01/oracle; \
      mkdir -p tmp ; cd tmp;  \
      jar xf $patch_file; \
      tux_patch=`find . -name *.zip`; \
      /u01/oracle/tuxHome/OPatch/opatch apply $tux_patch; \
      cd ; rm -rf tmp $patch_file; \
    done

WORKDIR /u01/oracle

EXPOSE 22 8080


# Define ENTRYPOINT. 
ENTRYPOINT ["/u01/oracle/init.sh"]
