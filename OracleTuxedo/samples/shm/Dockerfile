
# Pull Tuxedo base image
FROM oracle/tuxedo:12.1.3

MAINTAINER Todd Little <todd.little@oracle.com>
COPY simpapp_runme.sh /home/tuxtest/

USER root
RUN chown tuxtest:tuxtest -R /home/tuxtest

USER tuxtest
WORKDIR /home/tuxtest
RUN sh -x ./simpapp_runme.sh

