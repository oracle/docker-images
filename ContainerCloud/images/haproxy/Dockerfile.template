FROM __REGISTRY_NAME__/confd:__VERSION_CONFD__

RUN apk upgrade && \
    apk update && \
    apk add haproxy

# Lay down the configuration templates
ADD haproxy.toml.template \
    /etc/confd/conf.d/haproxy.toml.template

ADD haproxy.cfg.template_orig \
    /etc/confd/templates/haproxy.cfg.template_orig

ADD haproxy.cfg.stub \
    /etc/haproxy/haproxy.cfg

# Make `haproxy` start automagically with `runit`
RUN mkdir -pv /etc/sv/haproxy && \
    chmod 2775 /etc/sv/haproxy && \
    ln -sv /etc/sv/haproxy /service

ADD haproxy.sh \
    /etc/sv/haproxy/run

ENTRYPOINT ["/sbin/runsvdir", "/service"]
