# 
# Before run the MP sample, you need first run the docker project that creates a Tuxedo docker image containing the simpapp application
# 

# Pull base image
FROM oracle/tuxedo:<VERSION>

MAINTAINER Todd Little <todd.little@oracle.com>
COPY simpapp_runme.sh simpappmp_runme.sh sleep.sh start_tlisten.sh /home/oracle/

USER root
RUN chown oracle:oracle -R /home/oracle

USER oracle
RUN hostname; mkdir /home/oracle/simpappmp

WORKDIR /home/oracle/simpappmp

RUN sh -x ../simpapp_runme.sh
