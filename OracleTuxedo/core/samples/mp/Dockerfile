# 
# Before run the MP sample, you need first run the docker project that creates a Tuxedo docker image containing the simpapp application
# 

# Pull base image
FROM oracle/tuxedo:<VERSION>

MAINTAINER Judy Liu<judy.liu@oracle.com>
COPY simpapp_runme.sh simpappmp_runme.sh sleep.sh start_tlisten.sh /u01/oracle/

USER root
RUN chown oracle:oracle -R /u01/oracle

USER oracle
RUN hostname; mkdir /u01/oracle/simpappmp

WORKDIR /u01/oracle/simpappmp

RUN sh -x ../simpappmp_runme.sh
