# Copyright (c) 2021, 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:8

RUN dnf -y module enable ruby:2.7 nodejs:14 && \
    dnf -y install ruby ruby-libs ruby-devel ruby-irb \
                   nodejs npm \
                   rubygems rubygem-rake rubygem-bundler rubygem-bigdecimal rubygem-json \
                   sqlite-devel gcc gcc-c++ make redhat-rpm-config && \
    rm -rf /var/cache/dnf

CMD ["irb"]
