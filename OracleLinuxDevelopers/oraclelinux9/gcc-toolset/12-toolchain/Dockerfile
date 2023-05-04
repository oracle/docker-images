# Copyright (c) 2023 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:9

RUN dnf -y install gcc-toolset-12-gcc \
                   gcc-toolset-12-gcc-c++ \
                   gcc-toolset-12-gcc-gfortran \
                   gcc-toolset-12-gdb && \
    dnf -y clean all

# Copy the entrypoint script and ensure it's executable
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

# Enable the SCL via entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

# Set the default CMD to start an interactive bash shell
CMD [ "interactive-shell" ]
