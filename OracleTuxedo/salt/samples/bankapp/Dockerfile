# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Pull Tuxedo base image
FROM oracle/tuxedo:latest
#ENV TUXDIR=/u01/oracle/tuxHome/tuxedo22.1.0.0.0

LABEL maintainer="helptuxedo_ww_grp@oracle.com"

COPY . /u01/data/bankapp

USER root
RUN chown oracle:oracle -R /u01/data/ && \
    chmod +x /u01/data/bankapp/start.sh

USER oracle
WORKDIR /u01/data/bankapp
ENTRYPOINT ["/u01/data/bankapp/start.sh"]
