FROM __REGISTRY_NAME__/confd:__VERSION_CONFD__

RUN apk upgrade && \
    apk update && \
    apk add nginx

# Lay down the configuration templates
ADD nginx.toml.template \
    /etc/confd/conf.d/nginx.toml.template

ADD nginx.conf.template_orig \
    /etc/confd/templates/nginx.conf.template_orig

RUN mkdir -pv /etc/sv/nginx && \
    chmod 2775 /etc/sv/nginx && \
    ln -sv /etc/sv/nginx /service && \
    mkdir -p /run/nginx

ADD nginx.sh \
    /etc/sv/nginx/run

ENTRYPOINT ["/sbin/runsvdir", "/service"]
