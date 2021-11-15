FROM __REGISTRY_NAME__/confd:__VERSION_CONFD__

RUN apk upgrade && \
    apk update && \
    apk add nginx

# Lay down the configuration templates
ADD confd-files/99-app.toml \
    /etc/confd/conf.d/99-app.toml
ADD confd-files/99-app.template \
    /etc/confd/templates/99-app.template

ADD confd-files/00-upstream-blue.toml.toml \
    /etc/confd/conf.d/00-upstream-blue.toml.toml
ADD confd-files/00-upstream-blue.toml.template \
    /etc/confd/templates/00-upstream-blue.toml.template
ADD confd-files/00-upstream-blue.template.toml \
    /etc/confd/conf.d/00-upstream-blue.template.toml
ADD confd-files/00-upstream-blue.template.template \
    /etc/confd/templates/00-upstream-blue.template.template

ADD confd-files/00-upstream-green.toml.toml \
    /etc/confd/conf.d/00-upstream-green.toml.toml
ADD confd-files/00-upstream-green.toml.template \
    /etc/confd/templates/00-upstream-green.toml.template
ADD confd-files/00-upstream-green.template.toml \
    /etc/confd/conf.d/00-upstream-green.template.toml
ADD confd-files/00-upstream-green.template.template \
    /etc/confd/templates/00-upstream-green.template.template

ADD nginx.conf /etc/nginx/nginx.conf

RUN mkdir -pv /etc/sv/nginx && \
    chmod 2775 /etc/sv/nginx && \
    ln -sv /etc/sv/nginx /service && \
    mkdir -p /run/nginx /etc/nginx/sites-enabled

ADD nginx.sh /etc/sv/nginx/run

# Override the confd start script
ADD confd.sh /etc/sv/confd/run

# Cleanup unneeded files from upstream confd image
RUN rm /etc/confd/conf.d/hello-world.toml.template \
       /etc/confd/templates/hello-world.conf.template_orig

ENTRYPOINT ["/sbin/runsvdir", "/service"]
