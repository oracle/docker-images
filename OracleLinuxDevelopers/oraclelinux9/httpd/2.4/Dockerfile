FROM ghcr.io/oracle/oraclelinux:9

RUN dnf install -y httpd && \
    rm -rf /var/cache/dnf

CMD ["httpd", "-DFOREGROUND"]