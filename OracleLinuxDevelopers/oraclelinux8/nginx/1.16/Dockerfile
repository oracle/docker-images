# Copyright (c) 2021, 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:8

RUN \
    # Explicitly disable PHP to suppress conflicting requests error
    dnf -y module disable php \
    && \
    dnf -y module enable nginx:1.16 && \
    dnf -y install nginx && \
    rm -rf /var/cache/dnf \
    && \
    # forward request and error logs to container engine log collector
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80/tcp
EXPOSE 443/tcp

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
