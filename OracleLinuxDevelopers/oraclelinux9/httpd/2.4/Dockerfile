FROM ghcr.io/oracle/oraclelinux:9

RUN dnf install -y httpd mod_ssl && \
    rm -rf /var/cache/dnf

ENV CERTIFICATE_DIR /etc/pki/tls/certs
ENV KEY_DIR /etc/pki/tls/private

COPY ./entrypoint.sh /opt/entrypoint.sh

CMD ["/opt/entrypoint.sh"]