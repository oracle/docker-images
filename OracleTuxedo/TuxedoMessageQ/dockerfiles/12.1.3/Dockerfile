# Pull Tuxedo base image
FROM oracle/tuxedo:12.1.3

MAINTAINER Judy Liu <judy.liu@oracle.com>
COPY install.sh *.zip  tuxedotmq12.1.3.rsp /home/oracle/Downloads/

USER root
RUN chown oracle:oracle -R /home/oracle/

WORKDIR /home/oracle/Downloads
USER oracle
# Install Tuxedo OTMQ
RUN sh install.sh otmq121300_64_Linux_x86.zip
ENV TUXDIR /home/oracle/tuxHome/tuxedo12.1.3.0.0

# Clean up installer files
RUN rm -f *.zip

USER oracle
WORKDIR /home/oracle
