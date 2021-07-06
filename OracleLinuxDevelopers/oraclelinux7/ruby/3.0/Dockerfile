# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:7-slim

RUN yum -y install oracle-softwarecollection-release-el7 && \
    yum -y install rh-ruby30 \
                   rh-ruby30-ruby-devel \
                   rh-ruby30-rubygem-rake \
                   rh-ruby30-rubygem-bundler \
                   gcc make && \
    rm -rf /var/cache/yum

# Enable the SCL via environment modification
ENV PATH=/opt/rh/rh-ruby30/root/usr/local/bin:/opt/rh/rh-ruby30/root/usr/bin${PATH:+:${PATH}} \
    LD_LIBRARY_PATH=/opt/rh/rh-ruby30/root/usr/local/lib64:/opt/rh/rh-ruby30/root/usr/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}} \
    MANPATH=/opt/rh/rh-ruby30/root/usr/local/share/man:/opt/rh/rh-ruby30/root/usr/share/man:${MANPATH} \
    PKG_CONFIG_PATH=/opt/rh/rh-ruby30/root/usr/local/lib64/pkgconfig:/opt/rh/rh-ruby30/root/usr/lib64/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}} \
    XDG_DATA_DIRS=/opt/rh/rh-ruby30/root/usr/local/share:/opt/rh/rh-ruby30/root/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}

CMD ["irb"]
