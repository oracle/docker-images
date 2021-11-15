# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
FROM oraclelinux:7-slim

RUN yum -y install oracle-softwarecollection-release-el7 && \
    yum -y install rh-ruby27 \
                   rh-ruby27-ruby-devel \
                   rh-ruby27-rubygem-rake \
                   rh-ruby27-rubygem-bundler \
                   rh-nodejs14 \
                   rh-nodejs14-npm \
                   sqlite-devel \
                   gcc gcc-c++ make && \
    rm -rf /var/cache/yum

# Enable the Ruby 2.7 SCL via environment modification
ENV PATH=/opt/rh/rh-ruby27/root/usr/local/bin:/opt/rh/rh-ruby27/root/usr/bin${PATH:+:${PATH}} \
    LD_LIBRARY_PATH=/opt/rh/rh-ruby27/root/usr/local/lib64:/opt/rh/rh-ruby27/root/usr/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}} \
    MANPATH=/opt/rh/rh-ruby27/root/usr/local/share/man:/opt/rh/rh-ruby27/root/usr/share/man:${MANPATH} \
    PKG_CONFIG_PATH=/opt/rh/rh-ruby27/root/usr/local/lib64/pkgconfig:/opt/rh/rh-ruby27/root/usr/lib64/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}} \
    XDG_DATA_DIRS=/opt/rh/rh-ruby27/root/usr/local/share:/opt/rh/rh-ruby27/root/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}

# Enable the Node.js SCL via environmental modification
ENV PATH=/opt/rh/rh-nodejs14/root/usr/bin${PATH:+:${PATH}} \
    LD_LIBRARY_PATH=/opt/rh/rh-nodejs14/root/usr/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}} \
    PYTHONPATH=/opt/rh/rh-nodejs14/root/usr/lib/python2.7/site-packages${PYTHONPATH:+:${PYTHONPATH}} \
    MANPATH=/opt/rh/rh-nodejs14/root/usr/share/man:${MANPATH}

CMD ["irb"]
