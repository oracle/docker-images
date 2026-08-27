# Copyright (c) 2026 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:10-slim

RUN microdnf -y install python3.14 python3.14-pip && \
    ln -s /usr/bin/python3.14 /usr/local/bin/python && \
    ln -s /usr/bin/pip3.14 /usr/local/bin/pip && \
    microdnf clean all

CMD ["python", "-V"]
