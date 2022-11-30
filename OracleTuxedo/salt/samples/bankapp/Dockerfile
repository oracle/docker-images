# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Pull Tuxedo base image (which also sets TUXDIR)
FROM oracle/tuxedo:22.1.0.0.0

LABEL maintainer="helptuxedo_ww_grp@oracle.com"

COPY . /u01/data/bankapp

USER root
RUN yum -y install make && \
    chown oracle:oracle -R /u01/data/ && \
    chmod +x /u01/data/bankapp/start.sh && \
    chmod +x /u01/data/bankapp/stop_server.sh

USER oracle
WORKDIR /u01/data/bankapp
ENTRYPOINT ["/u01/data/bankapp/start.sh"]
