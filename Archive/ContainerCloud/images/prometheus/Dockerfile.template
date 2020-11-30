FROM __REGISTRY_NAME__/confd:__VERSION_CONFD__

# Upgrade OS and shoehorn in glibc
# thanks to sdurrheimer/alpine-glibc and
# Andy Shinn - https://github.com/gliderlabs/docker-alpine/issues/11
#
ENV GLIBC_VERSION="2.23-r3" \
    PROM_VER="0.20.0" \
    GLIBC_URL="https://github.com/andyshinn/alpine-pkg-glibc/releases/download" \
    GH_URL="https://github.com/prometheus/prometheus/releases/download"

#RUN apk add --update -t deps wget ca-certificates \
RUN apk upgrade && apk update && apk add -t deps wget && \
    wget --no-check-certificate \
      -O /tmp/glibc-${GLIBC_VERSION}.apk \
      ${GLIBC_URL}/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk && \
    wget --no-check-certificate \
      -O /tmp/glibc-bin-${GLIBC_VERSION}.apk \
      ${GLIBC_URL}/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk && \
    apk add --allow-untrusted /tmp/glibc-${GLIBC_VERSION}.apk /tmp/glibc-bin-${GLIBC_VERSION}.apk && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib/ && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

# Get prometheus from github releases
RUN wget --no-check-certificate \
      -O /tmp/prometheus.tar.gz \
      ${GH_URL}/${PROM_VER}/prometheus-${PROM_VER}.linux-amd64.tar.gz && \
    tar -xzf /tmp/prometheus.tar.gz -C /tmp && \
    mkdir -p /etc/prometheus && \
    mv /tmp/prometheus-${PROM_VER}.linux-amd64/prometheus /bin/ && \
    mv /tmp/prometheus-${PROM_VER}.linux-amd64/promtool /bin/ && \
    mv /tmp/prometheus-${PROM_VER}.linux-amd64/console_libraries/ \
      /etc/prometheus/ && \
    mv /tmp/prometheus-${PROM_VER}.linux-amd64/consoles/ \
      /etc/prometheus/ && \
    rm -rfv /tmp/prometheus*

RUN apk del --purge deps && \
    rm /tmp/* /var/cache/apk/*

# Basic config so prometheus starts even if there is a problem with confd
ADD prometheus.yml.stub \
    /etc/prometheus/prometheus.yml

ADD prometheus.yml.template_orig \
    /etc/confd/templates/prometheus.yml.template_orig

ADD prometheus.toml.template \
    /etc/confd/conf.d/prometheus.toml.template

RUN mkdir -pv /etc/sv/prometheus && \
    chmod 2775 /etc/sv/prometheus && \
    ln -sv /etc/sv/prometheus /service

ADD prometheus.sh \
    /etc/sv/prometheus/run

ENTRYPOINT ["/sbin/runsvdir", "/service"]
