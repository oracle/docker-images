# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux8-python:3.9

RUN python3 -m pip install --upgrade pip \
    && python3 -m pip install oci-cli \
    && cp /usr/local/lib/python3.9/site-packages/oci_cli/bin/oci_autocomplete.sh /usr/local/bin/oci_autocomplete.sh \
    && chmod +x /usr/local/bin/oci_autocomplete.sh \
    && useradd -m -d /oracle oracle \
    && echo '[[ -e "/usr/local/bin/oci_autocomplete.sh" ]] && source "/usr/local/bin/oci_autocomplete.sh"' >> /oracle/.bashrc

WORKDIR /oracle
USER oracle

ENTRYPOINT ["oci"]
CMD ["--help"]
