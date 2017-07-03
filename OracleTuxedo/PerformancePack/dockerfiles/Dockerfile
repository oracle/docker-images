# Pull Tuxedo base image
FROM oracle/tuxedo:12.2.2

MAINTAINER Judy Liu <judy.liu@oracle.com>
COPY perfpack_runme.sh /home/oracle/

USER root
RUN chown oracle:oracle -R /home/oracle/

USER oracle
WORKDIR /home/oracle
ENV PATH=.:$PATH

