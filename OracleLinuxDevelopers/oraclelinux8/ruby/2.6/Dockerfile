# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM ghcr.io/djelibeybi/oraclelinux8-compat:8-slim

COPY ruby.module  /etc/dnf/modules.d/ruby.module

RUN microdnf install ruby \
                     ruby-libs \
                     ruby-devel \
                     ruby-irb \
                     rubygems \
                     rubygem-rake \
                     rubygem-bundler \
                     gcc make \
    && microdnf clean all

CMD ["irb"]
