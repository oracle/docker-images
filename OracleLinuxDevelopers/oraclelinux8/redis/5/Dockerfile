# Copyright (c) 2023 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:8

RUN dnf install -y redis && \
    rm -rf /var/cache/dnf

RUN /bin/bash -o pipefail -c "sed 's/protected-mode yes/protected-mode no/g' /etc/redis.conf | \
    sed 's/^bind/#bind/g' - | sed 's/^logfile .*/logfile \"\"/g' - > /etc/docker.conf"

EXPOSE 6379

CMD ["redis-server", "/etc/docker.conf"]