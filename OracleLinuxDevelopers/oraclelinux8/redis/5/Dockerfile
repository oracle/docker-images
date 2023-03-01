# Copyright (c) 2020, 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:8

RUN dnf install -y redis && \
    rm -rf /var/cache/dnf

RUN /bin/bash -o pipefail -c "sed 's/protected-mode yes/protected-mode no/g' /etc/redis.conf | \
    sed 's/^bind/#bind/g' - > /etc/docker.conf"

CMD ["redis-server", "/etc/docker.conf"]