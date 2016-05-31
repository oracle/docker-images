
# Pull Tuxedo base image
FROM oracle/tuxedo:<VERSION>

MAINTAINER Todd Little <todd.little@oracle.com>
COPY simpapp_runme.sh /home/oracle/

USER root
RUN chown oracle:oracle -R /home/oracle

USER oracle
WORKDIR /home/oracle
RUN sh -x ./simpapp_runme.sh

