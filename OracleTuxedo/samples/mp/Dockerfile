# 
# Before run the MP sample, you need first run the docker project that creates a Tuxedo docker image containing the simpapp application
# 

# Pull base image
FROM oracle/tuxedo:12.1.3

MAINTAINER Todd Little <todd.little@oracle.com>
COPY simpapp_runme.sh simpappmp_runme.sh sleep.sh start_tlisten.sh /home/tuxtest/

USER root
RUN chown tuxtest:tuxtest -R /home/tuxtest

USER tuxtest
RUN hostname; mkdir /home/tuxtest/simpappmp
WORKDIR /home/tuxtest/simpappmp
RUN sh -x ../simpapp_runme.sh





