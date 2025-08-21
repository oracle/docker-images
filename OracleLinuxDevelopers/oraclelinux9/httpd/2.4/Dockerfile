FROM ghcr.io/oracle/oraclelinux:9

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