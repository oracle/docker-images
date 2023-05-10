# Copyright (c) 2023 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:8

RUN \
    dnf -y install haproxy && \
    rm -rf /var/cache/dnf

EXPOSE 5000

CMD ["/usr/sbin/haproxy", "-p", "/run/haproxy.pid", "-f", "/etc/haproxy/haproxy.cfg", "-W", "-db"]
