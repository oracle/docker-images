# Copyright (c) 2023 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:9

RUN dnf install -y redis && \
    rm -rf /var/cache/dnf

RUN sed -i.bak \
    -e 's/protected-mode yes/protected-mode no/g' \
    -e 's/^bind/# bind/g' \
    -e 's/^logfile .*/logfile \"\"/g' \
    /etc/redis/redis.conf

EXPOSE 6379

CMD ["redis-server", "/etc/redis/redis.conf"]
