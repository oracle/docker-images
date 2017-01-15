FROM __REGISTRY_NAME__/runit:__VERSION_RUNIT__

RUN apk upgrade && apk update && apk add wget

ENV CONFD_VERSION=0.11.0 \
    CONFD_URL=https://github.com/kelseyhightower/confd/releases/download

RUN wget --no-check-certificate \
    -O /usr/bin/confd \
    ${CONFD_URL}/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64 && \
    chmod +x /usr/bin/confd

ADD confd.sh /etc/sv/confd/run

RUN \
    mkdir -pv /etc/sv/confd && \
    chmod +x /etc/sv/confd/run && \
    mkdir -pv /etc/confd/conf.d && \
    mkdir -pv /etc/confd/templates && \
    ln -sv /etc/sv/confd /service

RUN apk del wget

# The TOML file serves to let confd know where to find and place various
# assests (e.g. the service key, the template used to write out the final
# config file, the restart command, etc)
ADD hello-world.toml.template /etc/confd/conf.d/
ADD hello-world.conf.template_orig /etc/confd/templates/
