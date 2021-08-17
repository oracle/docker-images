# LICENSE UPL 1.0
#
# Copyright (c) 2014, 2021, Oracle and/or its affiliates.
#
# Container image template for Oracle Instant Client
#
# HOW TO BUILD THIS IMAGE
# -----------------------
#
# Run:
#      $ docker build --pull -t oraclelinux7-instantclient:18 .
#      $ docker run -ti --rm oraclelinux7-instantclient:18 sqlplus -l /nolog
#

FROM oraclelinux:7

ARG release=18
ARG update=5

RUN  yum -y install oracle-release-el7 && yum-config-manager --enable ol7_oracle_instantclient && \
     yum -y install oracle-instantclient${release}.${update}-basic oracle-instantclient${release}.${update}-devel oracle-instantclient${release}.${update}-sqlplus && \
     rm -rf /var/cache/yum && \
     echo /usr/lib/oracle/${release}.${update}/client64/lib > /etc/ld.so.conf.d/oracle-instantclient${release}.${update}.conf && \
     ldconfig

ENV PATH=$PATH:/usr/lib/oracle/${release}.${update}/client64/bin

CMD ["sqlplus", "-v"]
