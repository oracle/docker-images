# See https://github.com/mhart/alpine-node/blob/master/Dockerfile
FROM mhart/alpine-node:6.3.0

RUN apk upgrade && apk update && apk add wget netcat-openbsd

ENV KIBANA_VERSION=4.5.2 \
    KIBANA_URL=https://download.elastic.co/kibana/kibana

RUN wget --no-check-certificate \
    -O /tmp/kibana-${KIBANA_VERSION}-linux-x64.tar.gz \
    ${KIBANA_URL}/kibana-${KIBANA_VERSION}-linux-x64.tar.gz

RUN tar xzf /tmp/kibana-${KIBANA_VERSION}-linux-x64.tar.gz \
      -C / && \
      rm /tmp/kibana-${KIBANA_VERSION}-linux-x64.tar.gz

RUN apk del wget && rm -rf /var/cache/apk/*

ENV KIBANA_DEST=/kibana-${KIBANA_VERSION}-linux-x64 \
    KIBANA_HOME=/kibana

COPY kibana.yml ${KIBANA_DEST}/config/kibana.yml
COPY entrypoint.sh ${KIBANA_DEST}/bin/entrypoint.sh
RUN ln -s ${KIBANA_DEST} ${KIBANA_HOME} && \
    chmod +x ${KIBANA_HOME}/bin/entrypoint.sh && \
    sed -i -e 's/\/node\/bin\/node/\/usr\/bin\/node/g' ${KIBANA_HOME}/bin/kibana
EXPOSE 5601
CMD ["/kibana/bin/entrypoint.sh"]
