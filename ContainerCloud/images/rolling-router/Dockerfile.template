FROM __REGISTRY_NAME__/confd:__VERSION_CONFD__

RUN apk upgrade && \
    apk update && \
    apk add nginx curl

# Lay down the configuration templates
ADD confd-files/00-upstream.toml.toml \
    /etc/confd/conf.d/00-upstream.toml.toml
ADD confd-files/00-upstream.toml.template \
    /etc/confd/templates/00-upstream.toml.template
ADD confd-files/00-upstream.template.toml \
    /etc/confd/conf.d/00-upstream.template.toml
ADD confd-files/00-upstream.template.template \
    /etc/confd/templates/00-upstream.template.template

ADD nginx.conf /etc/nginx/nginx.conf
ADD promote-candidate.sh /promote-candidate.sh

RUN mkdir -pv /etc/sv/nginx && \
    chmod 2775 /etc/sv/nginx && \
    ln -sv /etc/sv/nginx /service && \
    mkdir -p /run/nginx /etc/nginx/sites-enabled && \
    chmod +x /promote-candidate.sh

ADD nginx-files/99-app \
    /etc/nginx/sites-enabled/99-app
ADD nginx-files/00-upstream-placeholder \
    /etc/nginx/sites-enabled/00-upstream

ADD nginx.sh /etc/sv/nginx/run

# Override the confd start script
ADD confd.sh /etc/sv/confd/run

# Cleanup unneeded files from upstream confd image
RUN rm /etc/confd/conf.d/hello-world.toml.template \
       /etc/confd/templates/hello-world.conf.template_orig

ENTRYPOINT ["/sbin/runsvdir", "/service"]
