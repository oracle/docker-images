# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# The oraclelinux8-compat:8-slim image adds microdnf to the oraclelinux:8 image
# so that any automation that relied on microdnf continues to work
FROM ghcr.io/oracle/oraclelinux8-compat:8-slim

RUN dnf -y module enable ruby:2.7 nodejs:14 && \
    dnf -y install ruby ruby-libs ruby-devel ruby-irb \
                   nodejs npm \
                   rubygems rubygem-rake rubygem-bundler rubygem-bigdecimal rubygem-json \
                   sqlite-devel gcc gcc-c++ make redhat-rpm-config && \
    rm -rf /var/cache/dnf

CMD ["irb"]
