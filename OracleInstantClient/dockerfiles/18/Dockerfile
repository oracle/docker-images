# LICENSE UPL 1.0
#
# Copyright (c) 2014, 2019, Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
#
# Dockerfile template for Oracle Instant Client
#
# HOW TO BUILD THIS IMAGE
# -----------------------
#
# Run:
#      $ docker build -t oracle/instantclient:18 .
#
#
FROM oraclelinux:7-slim

RUN  yum-config-manager --enable ol7_oracle_instantclient && \
     yum -y install oracle-instantclient18.5-basic oracle-instantclient18.5-devel oracle-instantclient18.5-sqlplus && \
     rm -rf /var/cache/yum && \
     echo /usr/lib/oracle/18.5/client64/lib > /etc/ld.so.conf.d/oracle-instantclient18.5.conf && \
     ldconfig

ENV PATH=$PATH:/usr/lib/oracle/18.5/client64/bin

CMD ["sqlplus", "-v"]
