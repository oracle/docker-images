# Pull Tuxedo base image
FROM oracle/tuxedo:12.2.2

MAINTAINER Judy Liu<judy.liu@oracle.com>
COPY install.sh tuxedo12.2.2.rsp /home/oracle/Downloads/
COPY tuxedo122200_64_Linux_01_x86.zip /home/oracle/Downloads/

USER root
RUN chown oracle:oracle -R /home/oracle/

WORKDIR /home/oracle/Downloads
USER oracle
# Install Tuxedo, SALT, and TSAM Agent
RUN sh install.sh tuxedo122200_64_Linux_01_x86.zip
ENV TUXDIR /home/oracle/tuxHome/tuxedo12.2.2.0.0

# Clean up installer files
RUN rm -f *.zip

USER oracle
WORKDIR /home/oracle
