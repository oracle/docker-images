# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:10

RUN dnf install -y valkey && \
    rm -rf /var/cache/dnf

RUN sed -i.bak \
    -e 's/protected-mode yes/protected-mode no/g' \
    -e 's/^bind/# bind/g' \
    -e 's/^unixsocket/# unixsocket/g' \
    -e 's/^logfile .*/logfile \"\"/g' \
    /etc/valkey/valkey.conf

EXPOSE 6379

CMD ["valkey-server", "/etc/valkey/valkey.conf"]
