# 
# Before run the MP sample, you need first run the docker project that creates a Tuxedo docker image containing the simpapp application
# 

# Pull base image
FROM oracle/tuxedo:12.2.2

MAINTAINER Todd Little<todd.little@oracle.com>
COPY simpappmp_build.sh simpappmp_runme.sh sleep.sh start_tlisten.sh /u01/oracle/

USER root
RUN chown oracle:oracle -R /u01/oracle

USER oracle
RUN mkdir /u01/oracle/simpappmp

WORKDIR /u01/oracle/simpappmp

RUN sh -x ../simpappmp_build.sh

# Define ENTRYPOINT. 
ENTRYPOINT ["/u01/oracle/init.sh"]
