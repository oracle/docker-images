# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:8

RUN dnf -y install gcc-toolset-11-systemtap \
                   gcc-toolset-11-valgrind \
                   gcc-toolset-11-elfutils \
                   gcc-toolset-11-dyninst && \
    dnf -y clean all

# Copy the entrypoint script and ensure it's executable
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

# Enable the SCL via entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

# Set the default CMD to start an interactive bash shell
CMD [ "interactive-shell" ]
