# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM ghcr.io/djelibeybi/oraclelinux8-compat:8-slim

COPY ruby.module  /etc/dnf/modules.d/ruby.module
COPY nodejs.module /etc/dnf/modules.d/nodejs.module

RUN microdnf install ruby \
                     ruby-libs \
                     ruby-devel \
                     ruby-irb \
                     rubygems \
                     rubygem-rake \
                     rubygem-bundler \
                     rubygem-bigdecimal \
                     rubygem-json \
                     sqlite-devel \
                     gcc gcc-c++ make \
                     redhat-rpm-config \
                     nodejs npm \
    && microdnf clean all

CMD ["irb"]
