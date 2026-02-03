# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM ghcr.io/oracle/oraclelinux:10

RUN dnf install -y httpd mod_ssl && \
    rm -rf /var/cache/dnf

RUN sed -i \
    -e 's/^SSLCertificateFile .*/SSLCertificateFile \/certs\/fullchain.pem/g' \
    -e 's/^SSLCertificateKeyFile .*/SSLCertificateKeyFile \/certs\/privkey.pem/g' \
    /etc/httpd/conf.d/ssl.conf

RUN mkdir -p /certs

ENV CERTIFICATE_DIR /certs
ENV KEY_DIR /certs

COPY ./entrypoint.sh /opt/entrypoint.sh

CMD ["/opt/entrypoint.sh"]